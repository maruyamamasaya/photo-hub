// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "PhotoHubCore", platforms: [.iOS(.v17), .macOS(.v13)], products: [.library(name: "PhotoHubCore", targets: ["PhotoHubCore"])], targets: [.target(name: "PhotoHubCore", linkerSettings: [.linkedLibrary("sqlite3")]), .testTarget(name: "PhotoHubCoreTests", dependencies: ["PhotoHubCore"])])
