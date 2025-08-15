// swift-tools-version: 5.9
// swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenshotKit",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ScreenshotKit",
            targets: ["ScreenshotKit"]
        ),
        .executable(
            name: "ScreenshotExample",
            targets: ["ScreenshotExample"]
        )
    ],
    dependencies: [
        // 如果需要额外依赖，在这里添加
    ],
    targets: [
        .target(
            name: "ScreenshotKit",
            dependencies: [],
            path: "Sources/ScreenshotKit",
            exclude: ["Examples"]
        ),
        .executableTarget(
            name: "ScreenshotExample",
            dependencies: ["ScreenshotKit"],
            path: "Sources/ScreenshotKit/Examples"
        ),
        .testTarget(
            name: "ScreenshotKitTests",
            dependencies: ["ScreenshotKit"],
            path: "Tests/ScreenshotKitTests"
        ),
    ]
)