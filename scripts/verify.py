#!/usr/bin/env python3
"""Dependency-free verification of the current documentation foundation."""
import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = {
    'AGENTS.md': ['開始と探索', '変更', '終了と文書更新'],
    'CURRENT.md': ['Project:', '現在のフェーズ', '実装済み', '進行中', '未実装', '既知の問題', '技術的負債', '次に行うこと'],
    'ARCHITECTURE.md': ['System Overview', 'Technology Stack', 'Directory Structure', 'Main Components', 'Data Flow', 'API Structure', 'Database', 'Authentication', 'External Services', 'Deployment', 'Important Dependencies'],
    'CODEMAP.md': ['Primary paths', 'Search keywords', 'Key entry points', 'Related tests', '検索の使い分け'],
    'TESTING.md': ['Test Strategy', 'Fast Validation', 'Full Validation', '標準Verify', '変更別の検証', 'Lint', 'Typecheck', 'Unit', 'Integration', 'E2E', 'Build'],
    'OPERATIONS.md': ['Local Development', 'Environment Variables', 'Database Setup', 'External Services', 'Build', 'Deploy', 'Troubleshooting'],
    'README.md': [],
    'decisions/README.md': ['Context', 'Decision', 'Reason', 'Alternatives', 'Consequences'],
    'sessions/README.md': ['Request', 'Investigation', 'Changes', 'Files Changed', 'Validation', 'Result', 'Remaining Issues'],
}
# Guardrails for navigation documents; detailed material belongs in linked files.
LIMITS = {'AGENTS.md': 120, 'CURRENT.md': 80, 'CODEMAP.md': 200}
LINK = re.compile(r'\[[^\]]*\]\((<[^>]+>|[^\s)]+)(?:\s+"[^"]*")?\)')


def local_links(path, content):
    """Check relative file destinations; anchors and remote URLs are not validated."""
    errors = []
    for match in LINK.finditer(content):
        target = match.group(1).strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        destination = (path.parent / unquote(parsed.path)).resolve()
        if not destination.exists():
            errors.append(f'{path.relative_to(ROOT)}: missing link destination {target}')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fast', action='store_true', help='check required files and local links only')
    args = parser.parse_args()
    errors = []
    for name in [*REQUIRED, 'scripts/verify.py']:
        if not (ROOT / name).is_file():
            errors.append(f'missing required file: {name}')
    for name in ['decisions', 'sessions']:
        if not (ROOT / name).is_dir():
            errors.append(f'missing directory: {name}')
    for path in sorted(ROOT.rglob('*.md')):
        relative = path.relative_to(ROOT)
        if any(part.startswith('.') or part in {'node_modules', 'vendor', 'dist', 'build'} for part in relative.parts):
            continue
        try:
            content = path.read_text(encoding='utf-8')
        except (OSError, UnicodeError) as exc:
            errors.append(f'{relative}: cannot read UTF-8: {exc}')
            continue
        errors.extend(local_links(path, content))
        if args.fast:
            continue
        name = relative.as_posix()
        for marker in REQUIRED.get(name, []):
            if marker not in content:
                errors.append(f'{name}: missing required marker {marker}')
        limit = LIMITS.get(name, 120 if name.endswith('/AGENTS.md') else None)
        if limit is not None and len(content.splitlines()) > limit:
            errors.append(f'{name}: exceeds {limit} lines; move details to a linked source')
        if name.startswith('sessions/') and name != 'sessions/README.md':
            if len(content.splitlines()) > 120:
                errors.append(f'{name}: exceeds 120 lines; keep results concise')
    if not args.fast and (ROOT / 'README.md').is_file():
        readme = (ROOT / 'README.md').read_text(encoding='utf-8')
        for name in list(REQUIRED)[:6]:
            if f']({name})' not in readme:
                errors.append(f'README.md: missing navigation link to {name}')
    if errors:
        for error in errors:
            print(f'ERROR: {error}')
        return 1
    print(f'PASS: documentation verification ({"fast" if args.fast else "full"})')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
