import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Shared API groundwork; the existing PhotoHub app is not switched to this client yet.
public actor AssetLibraryAPIClient {
    private let baseURL: URL
    private let session: URLSession
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    public func assets(query: String = "", cursor: String? = nil) async throws -> AssetPage {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/v1/assets"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        return try await get(components.url!, as: AssetPage.self)
    }
    public func asset(id: String) async throws -> Asset {
        try await get(baseURL.appendingPathComponent("api/v1/assets").appendingPathComponent(id), as: Asset.self)
    }
    public func fileURL(assetID: String, fileID: String) -> URL {
        baseURL.appendingPathComponent("api/v1/assets").appendingPathComponent(assetID).appendingPathComponent("files").appendingPathComponent(fileID).appendingPathComponent("content")
    }
    private func get<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let error = try? JSONDecoder().decode(ApiError.self, from: data) {
                throw ClientError.api(error.code, error.message)
            }
            throw ClientError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    public enum ClientError: Error { case api(String, String), invalidResponse }
}
