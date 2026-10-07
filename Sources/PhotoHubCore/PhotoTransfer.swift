import Foundation

public enum PhotoTransfer {
    /// Verifies every representation. Caller persists uploading before this call and
    /// only persists uploaded after it returns successfully.
    public static func upload(photo: Photo, directory: URL, store: ObjectStore, progress: @escaping (Double) -> Void) async throws {
        for (index, kind) in ImageKind.allCases.enumerated() {
            let key = ObjectKeys.photo(owner: store.owner, id: photo.id, kind: kind)
            guard photo.keys[kind.rawValue] == key else { throw HubError.configuration }
            let file = directory.appendingPathComponent(kind == .original ? "original" : "\(kind.rawValue).jpg")
            guard FileManager.default.fileExists(atPath: file.path) else { throw HubError.missingOriginal }
            let checksum = try Digest.checksum(file: file), bytes = try Digest.bytes(file: file)
            if kind == .original { guard checksum == photo.sha256 && bytes == photo.bytes else { throw HubError.integrity } }
            if let existing = try await store.head(key: key) {
                guard existing.bytes == bytes && existing.checksum == checksum else { throw HubError.integrity }
            } else {
                try await store.put(file: file, key: key, mime: kind == .original ? photo.mime : "image/jpeg", checksum: checksum) { fraction in progress((Double(index) + fraction) / 3) }
            }
            guard let confirmed = try await store.head(key: key), confirmed.bytes == bytes, confirmed.checksum == checksum else { throw HubError.integrity }
            progress(Double(index + 1) / 3)
        }
    }
}
