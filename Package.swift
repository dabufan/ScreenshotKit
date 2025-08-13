// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenshotKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ScreenshotKit",
            targets: ["ScreenshotKit"]
        ),
    ],
    dependencies: [
        // 如果需要额外依赖，在这里添加
    ],
    targets: [
        .target(
            name: "ScreenshotKit",
            dependencies: [],
            path: "Sources/ScreenshotKit"
        ),
        .testTarget(
            name: "ScreenshotKitTests",
            dependencies: ["ScreenshotKit"],
            path: "Tests/ScreenshotKitTests"
        ),
    ]
)