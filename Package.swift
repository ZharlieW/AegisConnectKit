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
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", from: "0.11.1")
    ],
    targets: [
        .target(
            name: "AegisConnectKit",
            dependencies: [
                .product(name: "libsecp256k1", package: "secp256k1.swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AegisConnectKitTests",
            dependencies: ["AegisConnectKit"],
            path: "Tests"
        ),
    ]
) 