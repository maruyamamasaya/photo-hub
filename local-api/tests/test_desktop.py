import json
import os
import queue
import secrets
import subprocess
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'local-api'))
from vault.app import create_app


class DesktopTests(unittest.TestCase):
    def setUp(self):
        folder = ROOT / '.local/test-runs'
        folder.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=folder)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.token = secrets.token_hex(32)

    def test_private_boundary_covers_ui_and_api(self):
        origin = 'http://127.0.0.1:49123'
        app = create_app(self.root / 'data', self.root / 'fixtures', desktop_token=self.token, desktop_origin=origin)
        with TestClient(app, base_url=origin) as client:
            for route in ['/', '/api/v1/status', '/api/v1/assets']:
                self.assertEqual(client.get(route).status_code, 401)
            headers = {'x-photo-hub-token': self.token}
            self.assertEqual(client.get('/api/v1/status', headers=headers).status_code, 200)
            self.assertEqual(client.get('/api/v1/status', headers={**headers, 'origin': 'http://127.0.0.1:8765'}).status_code, 403)
            self.assertEqual(client.get('/api/v1/status', headers={**headers, 'host': '127.0.0.1:8765'}).status_code, 403)
            response = client.get('/api/v1/status', headers={**headers, 'origin': origin})
            self.assertIn("script-src 'self'", response.headers['content-security-policy'])

    def start_child(self, root):
        process = subprocess.Popen([sys.executable, '-u', str(ROOT / 'local-api/desktop_run.py')],
                                   stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        def cleanup():
            if process.poll() is None:
                process.kill()
            process.wait(timeout=10)
            for stream in [process.stdin, process.stdout, process.stderr]:
                if not stream.closed:
                    stream.close()
        self.addCleanup(cleanup)
        process.stdin.write(json.dumps({'token': self.token, 'dataRoot': str(root), 'fixtures': str(self.root / 'fixtures')}) + '\n')
        process.stdin.flush()
        return process

    def ready(self, process):
        lines = queue.Queue()
        threading.Thread(target=lambda: lines.put(process.stdout.readline()), daemon=True).start()
        return json.loads(lines.get(timeout=10))

    def test_child_dynamic_port_lock_shutdown_and_restart(self):
        root = self.root / '日本語 library'
        child = self.start_child(root)
        info = self.ready(child)
        self.assertGreater(info['pid'], 0)  # venv launcher and actual Python may differ on Windows
        request = urllib.request.Request(info['origin'] + '/api/v1/status', headers={'X-Photo-Hub-Token': self.token})
        with urllib.request.urlopen(request, timeout=5) as response:
            self.assertEqual(json.load(response)['mode'], 'local')
        with self.assertRaises(urllib.error.HTTPError) as failure:
            urllib.request.urlopen(info['origin'] + '/api/v1/status', timeout=5)
        self.assertEqual(failure.exception.code, 401)
        second = self.start_child(root)
        self.assertNotEqual(second.wait(timeout=10), 0)
        child.stdin.close()
        self.assertEqual(child.wait(timeout=10), 0)
        restarted = self.start_child(root)
        self.assertTrue(self.ready(restarted)['origin'].startswith('http://127.0.0.1:'))
        restarted.stdin.close()
        self.assertEqual(restarted.wait(timeout=10), 0)


if __name__ == '__main__':
    unittest.main()
