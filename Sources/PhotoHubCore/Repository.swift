import Foundation
import SQLite3

public final class Repository {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    public init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw HubError.database("open failed") }
        var versionStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA user_version", -1, &versionStatement, nil) == SQLITE_OK else { throw error() }
        let version = sqlite3_step(versionStatement) == SQLITE_ROW ? sqlite3_column_int(versionStatement, 0) : -1
        sqlite3_finalize(versionStatement)
        guard version == 0 || version == 1 else { throw HubError.database("unsupported schema version \(version)") }
        try execute("PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; CREATE TABLE IF NOT EXISTS photos(id TEXT PRIMARY KEY, asset TEXT NOT NULL UNIQUE, sha TEXT NOT NULL UNIQUE, captured REAL NOT NULL, payload BLOB NOT NULL); CREATE TABLE IF NOT EXISTS albums(id TEXT PRIMARY KEY, name TEXT NOT NULL, payload BLOB NOT NULL); CREATE TABLE IF NOT EXISTS memberships(album TEXT REFERENCES albums(id) ON DELETE CASCADE, photo TEXT REFERENCES photos(id) ON DELETE CASCADE, PRIMARY KEY(album,photo)); CREATE INDEX IF NOT EXISTS photos_captured ON photos(captured DESC,id); PRAGMA user_version=1;")
    }
    deinit { sqlite3_close(db) }
    private func execute(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw error() }
    }
    private func error() -> HubError { .database(String(cString: sqlite3_errmsg(db))) }
    private func statement(_ sql: String, values: [String] = [], blob: Data? = nil) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { throw error() }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (i, value) in values.enumerated() { sqlite3_bind_text(stmt, Int32(i + 1), value, -1, transient) }
        if let blob { _ = blob.withUnsafeBytes { sqlite3_bind_blob(stmt, Int32(values.count + 1), $0.baseAddress, Int32(blob.count), transient) } }
        return stmt
    }
    private func write(_ sql: String, values: [String], blob: Data? = nil) throws {
        let stmt = try statement(sql, values: values, blob: blob); defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw error() }
    }
    private func rows<T: Decodable>(_ sql: String, values: [String] = [], type: T.Type) throws -> [T] {
        let stmt = try statement(sql, values: values); defer { sqlite3_finalize(stmt) }
        var output: [T] = []
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw error() }
            let count = Int(sqlite3_column_bytes(stmt, 0))
            guard let pointer = sqlite3_column_blob(stmt, 0) else { throw error() }
            output.append(try decoder.decode(T.self, from: Data(bytes: pointer, count: count)))
        }
        return output
    }
    public func photos() throws -> [Photo] { try rows("SELECT payload FROM photos ORDER BY captured DESC,id", type: Photo.self) }
    public func albums() throws -> [Album] { try rows("SELECT payload FROM albums ORDER BY name,id", type: Album.self) }
    public func save(_ photo: Photo) throws {
        try write("INSERT INTO photos(id,asset,sha,captured,payload) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET asset=excluded.asset,sha=excluded.sha,captured=excluded.captured,payload=excluded.payload", values: [photo.id, photo.assetID, photo.sha256, String(photo.capturedAt.timeIntervalSince1970)], blob: encoder.encode(photo))
    }
    public func save(_ album: Album) throws { try write("INSERT INTO albums(id,name,payload) VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,payload=excluded.payload", values: [album.id, album.name], blob: encoder.encode(album)) }
    public func add(photoID: String, albumID: String) throws { try write("INSERT OR IGNORE INTO memberships(album,photo) VALUES(?,?)", values: [albumID, photoID]) }
    public func remove(photoID: String, albumID: String) throws { try write("DELETE FROM memberships WHERE album=? AND photo=?", values: [albumID, photoID]) }
    public func delete(photoID: String) throws { try write("DELETE FROM photos WHERE id=?", values: [photoID]) }
    public func memberships() throws -> [Membership] {
        let stmt = try statement("SELECT album,photo FROM memberships"); defer { sqlite3_finalize(stmt) }
        var result: [Membership] = []
        while sqlite3_step(stmt) == SQLITE_ROW { result.append(Membership(albumID: String(cString: sqlite3_column_text(stmt, 0)), photoID: String(cString: sqlite3_column_text(stmt, 1)))) }
        return result
    }
    public func recoverInterruptedUploads() throws {
        for var photo in try photos() where photo.state == .uploading { photo.state = .pending; try save(photo) }
    }
    public func snapshot(owner: String) throws -> Backup {
        let backup = Backup(owner: owner, photos: try photos(), albums: try albums(), memberships: try memberships())
        try backup.validate(owner: owner); return backup
    }
    public func restore(_ backup: Backup, owner: String) throws {
        try backup.validate(owner: owner)
        guard try photos().isEmpty, try albums().isEmpty else { throw HubError.notEmpty }
        try execute("BEGIN IMMEDIATE")
        do {
            for photo in backup.photos { try save(photo) }
            for album in backup.albums { try save(album) }
            for member in backup.memberships { try add(photoID: member.photoID, albumID: member.albumID) }
            try execute("COMMIT")
        } catch { try? execute("ROLLBACK"); throw error }
    }
}
