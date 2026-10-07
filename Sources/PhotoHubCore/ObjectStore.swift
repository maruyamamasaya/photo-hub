import Foundation
import CryptoKit

public struct ObjectInfo: Codable, Sendable {
    public var bytes: Int64
    public var checksum: String
    public init(bytes: Int64, checksum: String) { self.bytes = bytes; self.checksum = checksum }
}
public protocol ObjectStore {
    var owner: String { get }
    func head(key: String) async throws -> ObjectInfo?
    func put(file: URL, key: String, mime: String, checksum: String, progress: @escaping (Double) -> Void) async throws
    func get(key: String, destination: URL) async throws
    func delete(key: String) async throws
}
public enum Digest {
    public static func checksum(file: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: file); defer { try? handle.close() }
        var digest = SHA256()
        while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty { digest.update(data: data) }
        return Data(digest.finalize()).base64EncodedString()
    }
    public static func bytes(file: URL) throws -> Int64 { (try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? NSNumber)?.int64Value ?? 0 }
}
/// Development-only object storage. It never implements or disables production auth.
public final class LocalObjectStore: ObjectStore {
    public let owner = "local-development"
    public let root: URL
    public init(root: URL) throws { self.root = root.standardizedFileURL; try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    private func path(_ key: String) throws -> URL {
        guard key.hasPrefix("users/\(owner)/"), !key.split(separator: "/").contains(".."), !key.contains("\\") else { throw HubError.configuration }
        let path = root.appendingPathComponent(key).standardizedFileURL
        guard path.path.hasPrefix(root.path + "/") else { throw HubError.configuration }
        return path
    }
    public func head(key: String) async throws -> ObjectInfo? {
        let file = try path(key)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try ObjectInfo(bytes: Digest.bytes(file: file), checksum: Digest.checksum(file: file))
    }
    public func put(file: URL, key: String, mime: String, checksum: String, progress: @escaping (Double) -> Void) async throws {
        guard try Digest.checksum(file: file) == checksum else { throw HubError.integrity }
        let target = try path(key)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temporary = target.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try FileManager.default.copyItem(at: file, to: temporary)
        if FileManager.default.fileExists(atPath: target.path) { _ = try FileManager.default.replaceItemAt(target, withItemAt: temporary) }
        else { try FileManager.default.moveItem(at: temporary, to: target) }
        progress(1)
    }
    public func get(key: String, destination: URL) async throws {
        let source = try path(key)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.copyItem(at: source, to: destination)
    }
    public func delete(key: String) async throws {
        let file = try path(key)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }
}
public final class DiskCache {
    public let root: URL
    public var limit: Int64
    public init(root: URL, limit: Int64 = 512 * 1024 * 1024) throws { self.root = root; self.limit = limit; try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    public func file(id: String, kind: ImageKind) -> URL { root.appendingPathComponent("\(id)-\(kind.rawValue).jpg") }
    public func cached(id: String, kind: ImageKind) -> URL? {
        let url = file(id: id, kind: kind)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        return url
    }
    public func trim() throws {
        let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]).filter { !$0.lastPathComponent.hasPrefix(".") }
        let records = try files.map { url -> (URL, Date, Int64) in let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]); return (url, values.contentModificationDate ?? .distantPast, Int64(values.fileSize ?? 0)) }.sorted { $0.1 < $1.1 }
        var bytes = records.reduce(Int64(0)) { $0 + $1.2 }
        for record in records where bytes > limit { try FileManager.default.removeItem(at: record.0); bytes -= record.2 }
    }
}
