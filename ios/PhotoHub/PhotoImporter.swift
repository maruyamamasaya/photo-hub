import Foundation
import Photos
import ImageIO
import UniformTypeIdentifiers
import PhotoHubCore

struct ImportedPhoto {
    let photo: Photo
    let directory: URL
}
enum PhotoImporter {
    static func importAsset(id: String, pending: URL, cache: DiskCache) async throws -> ImportedPhoto {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw NSError(domain: "PhotoHub", code: 1, userInfo: [NSLocalizedDescriptionKey: "選択写真の原本へアクセスするため、写真へのアクセスを許可してください。"] ) }
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject,
              let resource = PHAssetResource.assetResources(for: asset).first(where: { $0.type == .photo }),
              let type = UTType(resource.uniformTypeIdentifier), [UTType.jpeg, .heic, .png].contains(where: { type.conforms(to: $0) }) else { throw HubError.unsupported }
        let photoID = UUID().uuidString.lowercased()
        let directory = pending.appendingPathComponent(photoID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = directory.appendingPathComponent("original")
        do {
            let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = true
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHAssetResourceManager.default().writeData(for: resource, toFile: original, options: options) { error in
                    if let error { continuation.resume(throwing: error) } else { continuation.resume() }
                }
            }
            let result = try await Task.detached(priority: .userInitiated) {
                try derivatives(original: original, directory: directory)
                return try (Digest.checksum(file: original), Digest.bytes(file: original))
            }.value
            var photo = Photo(id: photoID, assetID: id, filename: resource.originalFilename, capturedAt: asset.creationDate ?? Date(), mime: type.preferredMIMEType ?? "application/octet-stream", bytes: result.1, width: asset.pixelWidth, height: asset.pixelHeight, sha256: result.0)
            photo.state = .pending
            for kind in [ImageKind.thumbnail, .display] {
                let destination = cache.file(id: photoID, kind: kind)
                try FileManager.default.copyItem(at: directory.appendingPathComponent("\(kind.rawValue).jpg"), to: destination)
            }
            try cache.trim()
            return ImportedPhoto(photo: photo, directory: directory)
        } catch { try? FileManager.default.removeItem(at: directory); throw error }
    }
    static func derivatives(original: URL, directory: URL) throws {
        guard let source = CGImageSourceCreateWithURL(original as CFURL, nil) else { throw HubError.unsupported }
        for (name, size, quality) in [("thumbnail", 512, 0.75), ("display", 2048, 0.85)] {
            let options = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: size] as CFDictionary
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options),
                  let output = CGImageDestinationCreateWithURL(directory.appendingPathComponent("\(name).jpg") as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { throw HubError.unsupported }
            CGImageDestinationAddImage(output, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
            guard CGImageDestinationFinalize(output) else { throw HubError.integrity }
        }
    }
}
