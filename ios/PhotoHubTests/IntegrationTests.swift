import XCTest
import UIKit
import ImageIO
import PhotoHubCore
@testable import PhotoHub

@MainActor
final class IntegrationTests: XCTestCase {
    func testImageUploadBackupEmptyDatabaseRestoreAndDeletion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let objectRoot = root.appendingPathComponent("objects")
        let model = LibraryModel(baseURL: root.appendingPathComponent("one"), cacheURL: root.appendingPathComponent("cache-one"), developmentRoot: objectRoot)
        model.localMode = true
        let image = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 1500)).image { context in UIColor.systemBlue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 3000, height: 1500)) }
        let id = UUID().uuidString.lowercased(), directory = model.pending.appendingPathComponent(id)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = directory.appendingPathComponent("original"); try XCTUnwrap(image.pngData()).write(to: original)
        try PhotoImporter.derivatives(original: original, directory: directory)
        let photo = try Photo(id: id, assetID: "test-asset", filename: "test.png", capturedAt: Date(), mime: "image/png", bytes: Digest.bytes(file: original), width: 3000, height: 1500, sha256: Digest.checksum(file: original))
        try XCTUnwrap(model.repository).save(photo); try model.refresh()
        await model.uploadPending(); XCTAssertEqual(model.photos.first?.state, .uploaded)
        model.setFavorite(try XCTUnwrap(model.photos.first)); model.addAlbum(name: "旅行")
        model.toggleMembership(photo: try XCTUnwrap(model.photos.first), album: try XCTUnwrap(model.albums.first))
        await model.backup(); XCTAssertTrue(FileManager.default.fileExists(atPath: model.support.appendingPathComponent("backup.json").path))
        await model.backup() // latest pointer replacement, older snapshots retained
        let restored = LibraryModel(baseURL: root.appendingPathComponent("two"), cacheURL: root.appendingPathComponent("cache-two"), developmentRoot: objectRoot); restored.localMode = true
        await restored.restore()
        XCTAssertEqual(restored.photos.count, 1); XCTAssertEqual(restored.albums.first?.name, "旅行"); XCTAssertEqual(restored.members.count, 1); XCTAssertEqual(restored.photos.first?.favorite, true)
        let restoredPhoto = try XCTUnwrap(restored.photos.first)
        let imageFile = await restored.image(restoredPhoto, kind: .display)
        let file = try XCTUnwrap(imageFile), source = try XCTUnwrap(CGImageSourceCreateWithURL(file as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertLessThanOrEqual((properties[kCGImagePropertyPixelWidth] as? Int) ?? 9999, 2048)
        await restored.requestDelete(restoredPhoto); XCTAssertTrue(restored.photos.isEmpty); XCTAssertTrue(restored.members.isEmpty)
        let store = try LocalObjectStore(root: objectRoot)
        let absent = try await store.head(key: ObjectKeys.photo(owner: store.owner, id: id, kind: .original)); XCTAssertNil(absent)
    }
    func testUnconfiguredProductionNeverFallsBackToLocalStorage() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = LibraryModel(baseURL: root, cacheURL: root.appendingPathComponent("cache"))
        let previous = model.localMode; defer { model.localMode = previous }
        model.localMode = false; model.configuration = CloudConfiguration()
        let photo = Photo(assetID: "test", filename: "test.jpg", capturedAt: Date(), mime: "image/jpeg", bytes: 1, width: 1, height: 1, sha256: "pending")
        try XCTUnwrap(model.repository).save(photo); try model.refresh()
        await model.uploadPending()
        XCTAssertEqual(model.photos.first?.state, .pending); XCTAssertNotNil(model.message)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("DevelopmentObjects").path))
    }
    func testFailedUploadPreservesPendingOriginalAndRecovers() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = LibraryModel(baseURL: root, cacheURL: root.appendingPathComponent("cache")); model.localMode = true
        let id = UUID().uuidString.lowercased(), directory = model.pending.appendingPathComponent(id)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = directory.appendingPathComponent("original"); try Data("pending-original".utf8).write(to: original)
        let photo = try Photo(id: id, assetID: "test", filename: "test.jpg", capturedAt: Date(), mime: "image/jpeg", bytes: Digest.bytes(file: original), width: 1, height: 1, sha256: Digest.checksum(file: original))
        try XCTUnwrap(model.repository).save(photo); try model.refresh()
        await model.uploadPending()
        XCTAssertEqual(model.photos.first?.state, .failed); XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        for name in ["thumbnail", "display"] { try Data(name.utf8).write(to: directory.appendingPathComponent(name + ".jpg")) }
        await model.uploadPending(); XCTAssertEqual(model.photos.first?.state, .uploaded); XCTAssertEqual(model.photos.first?.id, id)
        await model.releaseOriginals(); XCTAssertTrue(FileManager.default.fileExists(atPath: original.path)) // development copies are protected
    }
}
