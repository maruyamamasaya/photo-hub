"""Generate synthetic PNG/JPEG/WebP samples, never read personal image folders."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent


def create_samples(destination, count=12):
    destination.mkdir(parents=True, exist_ok=True)
    palette = [('#d8d7bd', '#5d7058'), ('#e7c7b4', '#a5533d'), ('#cbd8db', '#47677a'), ('#e6dcbf', '#ae8d4a')]
    for index in range(count):
        extension = ['png', 'jpg', 'webp'][index % 3]
        path = destination / f'sample-{index + 1:04d}.{extension}'
        if path.exists():
            continue
        bg, fg = palette[index % len(palette)]
        image = Image.new('RGB', (900, 680), bg)
        draw = ImageDraw.Draw(image)
        # Architectural and material studies made locally for visual UI evaluation.
        shift = index % 17 * 8
        draw.rectangle((100 + shift, 120, 720, 580), fill=fg)
        draw.rectangle((140 + shift, 160, 680, 540), fill=bg)
        for step in range(6):
            x = 170 + step * 75
            draw.line((x, 170, x, 530), fill=fg, width=12)
        draw.ellipse((540, 50 + shift, 780, 290 + shift), fill='#f5eee1')
        draw.text((35, 630), f'STUDY / {index + 1:04d}', fill=fg)
        image.save(path)
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--count', type=int, default=12)
    args = parser.parse_args()
    if not 1 <= args.count <= 1000:
        parser.error('count must be 1..1000')
    create_samples(ROOT / '.local/fixtures', args.count)
    print(f'Generated {args.count} synthetic samples in .local/fixtures')
