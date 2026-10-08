"""Measure real local API queries with 1,000 generated originals in an isolated DB."""
import io
import json
import platform
import sys
import tempfile
import time
from pathlib import Path
from PIL import Image
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'local-api'))
from vault.app import create_app


def main():
    test_root = ROOT / '.local/benchmarks'
    test_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=test_root) as tmp:
        app = create_app(Path(tmp) / 'data', Path(tmp) / 'fixtures')
        vault = app.state.vault
        job_id = vault.new_job()
        start = time.perf_counter()
        for index in range(1000):
            stream = io.BytesIO()
            Image.new('RGB', (64, 64), (index % 256, index // 256, 120)).save(stream, 'PNG')
            stream.seek(0)
            vault.add_stream(job_id, f'study-{index:04d}.png', stream)
        import_seconds = time.perf_counter() - start
        with TestClient(app, base_url='http://127.0.0.1:8765') as client:
            measurements = {}
            for label, params in [('first_page', {'limit': 60}), ('search', {'q': 'study-09', 'limit': 60})]:
                times = []
                for _ in range(3):
                    start = time.perf_counter()
                    response = client.get('/api/v1/assets', params=params)
                    times.append((time.perf_counter() - start) * 1000)
                    assert response.status_code == 200, response.text
                measurements[label] = {'median_ms': round(sorted(times)[1], 2), 'total': response.json()['total'], 'returned': len(response.json()['items'])}
            ids, cursor = set(), None
            while True:
                params = {'limit': 100}
                if cursor: params['cursor'] = cursor
                page = client.get('/api/v1/assets', params=params).json()
                assert not ids.intersection(a['id'] for a in page['items'])
                ids.update(a['id'] for a in page['items'])
                cursor = page['nextCursor']
                if not cursor: break
            assert len(ids) == 1000
        result = {'platform': platform.platform(), 'python': platform.python_version(), 'assetCount': len(ids), 'imageSize': '64x64 generated PNG, originals + JPEG derivatives', 'import_seconds': round(import_seconds, 2), 'queries': measurements, 'scope': 'API/SQLite/file existence checks; browser scrolling and iPhone performance are separate'}
        (test_root / 'latest.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
        print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__': main()
