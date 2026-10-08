const { test } = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

test('Mac Close keeps API alive; activate recreates window; Quit stops API', async () => {
  // Simulated Electron events test our lifecycle; native macOS behavior needs a Mac.
  const app = new EventEmitter();
  let stops = 0;
  let launches = 0;
  let exits = 0;
  const windows = [];
  const handlers = new Map();
  Object.assign(app, {
    setPath() {}, requestSingleInstanceLock: () => true,
    whenReady: () => Promise.resolve(),
    quit() {
      const event = { prevented: false, preventDefault() { this.prevented = true; } };
      app.emit('before-quit', event);
      if (!event.prevented) exits++;
    },
  });
  class Window extends EventEmitter {
    constructor() {
      super(); windows.push(this); this.destroyed = false;
      this.webContents = new EventEmitter();
      this.webContents.setWindowOpenHandler = () => {};
      this.webContents.getURL = () => this.url;
    }
    isDestroyed() { return this.destroyed; }
    async loadURL(url) { this.url = url; }
    show() { this.shown = true; }
    destroy() { this.destroyed = true; this.emit('closed'); app.emit('window-all-closed'); }
  }
  const session = { fromPartition: () => ({
    setPermissionRequestHandler() {}, setPermissionCheckHandler() {},
    webRequest: { onBeforeRequest() {}, onBeforeSendHeaders() {} },
  }) };
  const electron = { app, BrowserWindow: Window, session,
    ipcMain: { handle: (name, callback) => handlers.set(name, callback) },
    Menu: { buildFromTemplate: value => value, setApplicationMenu() {} },
    dialog: { showErrorBox: (_title, message) => assert.fail(message), showOpenDialog: async () => ({ canceled: false, filePaths: ['/images/chosen'] }) },
  };
  const startApi = options => {
    launches++;
    assert.equal(options.python, path.join(path.resolve(__dirname, '..'), '.venv/bin/python'));
    return { ready: Promise.resolve({ origin: 'http://127.0.0.1:54321', token: 'test' }), stop: async () => { stops++; } };
  };
  const settle = () => new Promise(resolve => setImmediate(resolve));
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, 'main.cjs'), 'utf8'), {
    __dirname, console, URL, process: { platform: 'darwin', argv: [] },
    require(name) {
      if (name === 'electron') return electron;
      if (name === './api-process.cjs') return { startApi };
      if (name === './platform.cjs') return require('./platform.cjs');
      if (name === 'node:fs') return { existsSync: () => true };
      return require(name);
    },
  });
  await settle();
  assert.equal(windows.length, 1);
  assert.equal(windows[0].shown, true);
  const chooser = handlers.get('choose-storage-directory');
  assert.equal(await chooser({ sender: windows[0].webContents }), '/images/chosen');
  await assert.rejects(chooser({ sender: {} }), /Invalid sender/);
  windows[0].destroy();
  assert.equal(stops, 0);
  assert.equal(exits, 0);
  app.emit('activate');
  await settle();
  assert.equal(windows.length, 2);
  assert.equal(windows[1].shown, true);
  assert.equal(launches, 1);
  app.quit();
  await settle();
  assert.equal(stops, 1);
  assert.equal(exits, 1);
});
