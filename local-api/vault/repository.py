import sqlite3
from pathlib import Path
from contextlib import contextmanager

SCHEMA = """
CREATE TABLE IF NOT EXISTS assets (
 id TEXT PRIMARY KEY, libraryId TEXT NOT NULL, kind TEXT NOT NULL, name TEXT NOT NULL,
 note TEXT NOT NULL DEFAULT '', source TEXT NOT NULL DEFAULT 'import',
 createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL, capturedAt TEXT,
 favorite INTEGER NOT NULL DEFAULT 0, revision INTEGER NOT NULL DEFAULT 1,
 state TEXT NOT NULL DEFAULT 'ready', trashedAt TEXT
);
CREATE TABLE IF NOT EXISTS files (
 id TEXT PRIMARY KEY, assetId TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
 role TEXT NOT NULL, originalFilename TEXT NOT NULL, objectKey TEXT NOT NULL UNIQUE,
 mimeType TEXT NOT NULL, byteSize INTEGER NOT NULL, sha256 TEXT NOT NULL,
 width INTEGER, height INTEGER, state TEXT NOT NULL, error TEXT,
 UNIQUE(assetId, role)
);
CREATE UNIQUE INDEX IF NOT EXISTS original_hash ON files(sha256) WHERE role='original';
CREATE INDEX IF NOT EXISTS asset_order ON assets(createdAt, id);
CREATE TABLE IF NOT EXISTS tags (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE COLLATE NOCASE);
CREATE TABLE IF NOT EXISTS collections (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE COLLATE NOCASE);
CREATE TABLE IF NOT EXISTS asset_tags (assetId TEXT REFERENCES assets(id) ON DELETE CASCADE, itemId TEXT REFERENCES tags(id) ON DELETE CASCADE, PRIMARY KEY(assetId,itemId));
CREATE TABLE IF NOT EXISTS asset_collections (assetId TEXT REFERENCES assets(id) ON DELETE CASCADE, itemId TEXT REFERENCES collections(id) ON DELETE CASCADE, PRIMARY KEY(assetId,itemId));
CREATE TABLE IF NOT EXISTS jobs (id TEXT PRIMARY KEY, createdAt TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS import_items (
 id TEXT PRIMARY KEY, jobId TEXT NOT NULL REFERENCES jobs(id), filename TEXT NOT NULL,
 state TEXT NOT NULL, assetId TEXT, code TEXT, message TEXT NOT NULL DEFAULT '',
 stageKey TEXT NOT NULL
);

"""


class AssetRepository:
    def __init__(self, path):
        self.path = path
        with self.connect() as db:
            if db.execute('PRAGMA user_version').fetchone()[0] not in (0, 1, 2, 3, 4, 5, 6, 7):
                raise RuntimeError('Unsupported database version')
            db.executescript(SCHEMA)
            if 'originalExtension' not in [r['name'] for r in db.execute('PRAGMA table_info(assets)')]:
                db.execute("ALTER TABLE assets ADD COLUMN originalExtension TEXT NOT NULL DEFAULT ''")
                rows = db.execute("SELECT assetId,originalFilename FROM files WHERE role='original'").fetchall()
                db.executemany('UPDATE assets SET originalExtension=? WHERE id=?', [(Path(r['originalFilename']).suffix.lower().lstrip('.'), r['assetId']) for r in rows])
            db.execute('CREATE INDEX IF NOT EXISTS asset_extension ON assets(originalExtension)')
            db.execute('CREATE INDEX IF NOT EXISTS asset_updated ON assets(updatedAt,id)')
            db.execute('CREATE INDEX IF NOT EXISTS asset_captured ON assets(capturedAt,id)')
            db.execute('CREATE INDEX IF NOT EXISTS asset_name ON assets(name COLLATE NOCASE,id)')
            if 'archivedAt' not in [r['name'] for r in db.execute('PRAGMA table_info(assets)')]:
                db.execute('ALTER TABLE assets ADD COLUMN archivedAt TEXT')
            db.execute('CREATE INDEX IF NOT EXISTS asset_archive_order ON assets(trashedAt,archivedAt,createdAt,id)')
            columns = {r['name'] for r in db.execute('PRAGMA table_info(assets)')}
            for name, definition in [('storageLocation', "TEXT NOT NULL DEFAULT 'development-remote'"), ('originalOwnership', "TEXT NOT NULL DEFAULT 'managed'"), ('originalModifiedNs', 'INTEGER')]:
                if name not in columns:
                    db.execute(f'ALTER TABLE assets ADD COLUMN {name} {definition}')
            if 'referenceKey' not in {r['name'] for r in db.execute('PRAGMA table_info(import_items)')}:
                db.execute('ALTER TABLE import_items ADD COLUMN referenceKey TEXT')
            db.execute('CREATE INDEX IF NOT EXISTS asset_location ON assets(storageLocation)')
            db.execute('CREATE TABLE IF NOT EXISTS remote_originals (fileId TEXT PRIMARY KEY REFERENCES files(id) ON DELETE CASCADE, objectKey TEXT NOT NULL UNIQUE)')
            db.execute("INSERT OR IGNORE INTO remote_originals SELECT f.id,f.objectKey FROM files f JOIN assets a ON a.id=f.assetId WHERE f.role='original' AND a.storageLocation='development-remote'")
            db.execute('CREATE TABLE IF NOT EXISTS transfer_cleanup (assetId TEXT PRIMARY KEY REFERENCES assets(id) ON DELETE CASCADE, objectKey TEXT NOT NULL, sha256 TEXT NOT NULL)')
            db.execute('CREATE TABLE IF NOT EXISTS storage_roots (id TEXT PRIMARY KEY, path TEXT NOT NULL UNIQUE, syncedAt TEXT)')
            db.execute('CREATE TABLE IF NOT EXISTS local_sources (rootId TEXT REFERENCES storage_roots(id), relativePath TEXT NOT NULL, assetId TEXT REFERENCES assets(id) ON DELETE CASCADE, sha256 TEXT NOT NULL, PRIMARY KEY(rootId,relativePath))')
            db.execute("UPDATE assets SET archivedAt=NULL,revision=revision+1,updatedAt=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE storageLocation='local' AND archivedAt IS NOT NULL")
            db.execute('PRAGMA user_version=7')

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=15)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys=ON')
        db.execute('PRAGMA journal_mode=WAL')
        try:
            with db:
                yield db
        finally:
            db.close()

    def asset(self, asset_id):
        with self.connect() as db:
            row = db.execute('SELECT * FROM assets WHERE id=?', (asset_id,)).fetchone()
            if row is None:
                return None
            result = dict(row)
            del result['originalExtension']
            del result['originalModifiedNs']
            result['remoteAvailable'] = bool(db.execute('SELECT 1 FROM remote_originals r JOIN files f ON f.id=r.fileId WHERE f.assetId=?', (asset_id,)).fetchone())
            result['localCleanupPending'] = bool(db.execute('SELECT 1 FROM transfer_cleanup WHERE assetId=?', (asset_id,)).fetchone())
            result['favorite'] = bool(result['favorite'])
            result['files'] = [dict(f) for f in db.execute('SELECT * FROM files WHERE assetId=? ORDER BY role', (asset_id,))]
            for f in result['files']:
                del f['assetId']
            for entity in ('tags', 'collections'):
                result[entity] = [dict(r) for r in db.execute(f'SELECT e.* FROM {entity} e JOIN asset_{entity} m ON e.id=m.itemId WHERE m.assetId=? ORDER BY e.name', (asset_id,))]
            return result
