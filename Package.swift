// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "AegisConnectKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AegisConnectKit",
            targets: ["AegisConnectKit"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AegisConnectKit",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AegisConnectKitTests",
            dependencies: ["AegisConnectKit"],
            path: "Tests"
        ),
    ]
) 