import Foundation
import XCTest
@testable import AssetLibraryContract

final class ContractTests: XCTestCase {
    func testSharedFixtureDecodesAndRoundTrips() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "asset", withExtension: "json"))
        let asset = try JSONDecoder().decode(Asset.self, from: Data(contentsOf: url))
        XCTAssertEqual(asset.libraryId, "local-library")
        XCTAssertNil(asset.capturedAt)
        XCTAssertNil(asset.archivedAt)
        XCTAssertEqual(asset.files.first?.role, "original")
        let decoded = try JSONDecoder().decode(Asset.self, from: JSONEncoder().encode(asset))
        XCTAssertEqual(decoded.id, asset.id)
        XCTAssertEqual(decoded.tags.first?.name, "reference")
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(asset)) as? [String: Any])
        XCTAssertTrue(encoded["capturedAt"] is NSNull)
        XCTAssertTrue(encoded["trashedAt"] is NSNull)
        XCTAssertTrue(encoded["archivedAt"] is NSNull)
    }

    func testUnknownAssetKindIsPreserved() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "asset", withExtension: "json"))
        var value = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        value["kind"] = "future_asset_kind"
        let asset = try JSONDecoder().decode(Asset.self, from: JSONSerialization.data(withJSONObject: value))
        XCTAssertEqual(asset.kind, "future_asset_kind")
    }
}
