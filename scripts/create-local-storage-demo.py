"""Explicitly add three generated local images to the stopped development library."""
import argparse
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'local-api'))
from vault.service import Vault

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--library', choices=['web', 'desktop'], required=True)
args = parser.parse_args()
root = ROOT / '.local' / ('asset-library' if args.library == 'web' else 'desktop-library')
database = root / 'library.sqlite3'
if database.exists():
    backup = root / ('before-hybrid-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '.sqlite3')
    with sqlite3.connect(database) as source, sqlite3.connect(backup) as target:
        source.backup(target)
vault = Vault(root, ROOT / '.local/fixtures')
for index, name in enumerate(['local-demo-wave.png', 'local-demo-checker.png', 'local-demo-icon.png']):
    path = vault.local_directory / name
    if path.exists():
        continue
    size = 64 if index == 2 else 512
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0) if index == 2 else '#e7f2ef')
    draw = ImageDraw.Draw(image)
    if index == 0:
        for y in range(size):
            draw.line((0, y, size, y), fill=(30 + y // 8, 120 + y // 5, 180 + y // 10, 255))
        for x in range(-200, 600, 130):
            draw.arc((x, 100, x + 350, 480), 180, 360, fill='#b6ebe1', width=30)
    elif index == 1:
        for y in range(0, size, 64):
            for x in range(0, size, 64):
                draw.rectangle((x, y, x + 63, y + 63), fill='#dcaf71' if (x + y) // 64 % 2 else '#f7e8ce')
    else:
        draw.rounded_rectangle((4, 4, 60, 60), radius=14, fill='#287d62')
        draw.line((18, 32, 28, 42, 47, 22), fill='white', width=6)
    image.save(path, 'PNG')
result = vault.local_import()
assert all(item['state'] in ('ready', 'duplicate') for item in result['items']), result
print(f"PASS: {args.library}; {len(result['items'])} new local items; {vault.local_directory}")
