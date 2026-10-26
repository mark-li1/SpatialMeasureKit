// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpatialMeasureKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SpatialMeasureKit",
            targets: ["SpatialMeasureKit"]
        ),
    ],
    targets: [
        .target(
            name: "SpatialMeasureKit"
        ),
        .testTarget(
            name: "SpatialMeasureKitTests",
            dependencies: ["SpatialMeasureKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
