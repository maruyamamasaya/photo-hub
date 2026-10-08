const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pythonExecutable, menuTemplate } = require('./platform.cjs');

test('Mac development uses POSIX venv and native Close separate from Quit', () => {
  const root = path.resolve('library project');
  assert.equal(pythonExecutable(root, 'darwin', ''), path.join(root, '.venv/bin/python'));
  assert.equal(pythonExecutable(root, 'win32', ''), path.join(root, '.venv/Scripts/python.exe'));
  assert.equal(pythonExecutable(root, 'darwin', '/custom/python'), '/custom/python');
  const menus = menuTemplate('darwin', () => {});
  const appMenu = menus.find(menu => menu.label === 'Photo Hub');
  const fileMenu = menus.find(menu => menu.label === 'ファイル');
  assert.ok(appMenu.submenu.some(item => item.role === 'quit'));
  assert.ok(fileMenu.submenu.some(item => item.role === 'close'));
  assert.ok(!fileMenu.submenu.some(item => item.role === 'quit'));
  assert.ok(menus.some(menu => menu.role === 'windowMenu'));
  assert.ok(menuTemplate('win32', () => {})[0].submenu.some(item => item.role === 'quit'));
});
