const { spawn } = require('node:child_process');
const { createInterface } = require('node:readline');
const { randomBytes } = require('node:crypto');
const path = require('node:path');

function startApi({ root, dataRoot, python, onExit }) {
  const token = randomBytes(32).toString('hex');
  const child = spawn(python, ['-u', path.join(root, 'local-api/desktop_run.py')], {
    cwd: root, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'],
  });
  child.stdin.on('error', () => {});
  child.stdin.write(JSON.stringify({ token, dataRoot, fixtures: path.join(root, '.local/fixtures') }) + '\n');
  // Do not echo child output: startup credentials and user paths remain private.
  child.stderr.resume();
  let stopping = false;
  let serverPid;
  const exited = new Promise(resolve => { child.once('exit', resolve); child.once('error', resolve); });
  child.once('exit', code => { if (!stopping) onExit?.(code); });
  const ready = new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('APIの起動が時間内に完了しませんでした。')), 20000);
    const lines = createInterface({ input: child.stdout });
    const fail = () => { clearTimeout(timer); reject(new Error('APIを起動できません。Python環境とライブラリの使用状況を確認してください。')); };
    child.once('error', fail);
    child.once('exit', fail);
    lines.once('line', async line => {
      try {
        const info = JSON.parse(line);
        if (!/^http:\/\/127\.0\.0\.1:\d+$/.test(info.origin) || !Number.isSafeInteger(info.pid) || info.pid <= 0) throw new Error();
        const response = await fetch(`${info.origin}/api/v1/status`, {
          headers: { 'X-Photo-Hub-Token': token }, signal: AbortSignal.timeout(5000),
        });
        if (!response.ok || (await response.json()).mode !== 'local') throw new Error();
        serverPid = info.pid; // Windows venv launcher has a different PID.
        clearTimeout(timer);
        resolve({ origin: info.origin, token });
      } catch { fail(); }
    });
  });
  async function stop() {
    stopping = true;
    if (child.exitCode !== null || child.signalCode !== null) return;
    child.stdin.end();
    const timer = setTimeout(() => {
      if (serverPid) { try { process.kill(serverPid, 'SIGKILL'); } catch {} }
      child.kill('SIGKILL');
    }, 35000);
    await exited;
    clearTimeout(timer);
  }
  return { ready, stop, child, get serverPid() { return serverPid; } };
}
module.exports = { startApi };
