// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnforgeterCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "UnforgeterCore", targets: ["UnforgeterCore"])],
    targets: [
        .target(name: "UnforgeterCore"),
        .testTarget(name: "UnforgeterCoreTests", dependencies: ["UnforgeterCore"])
    ],
    swiftLanguageVersions: [.v5]
)
