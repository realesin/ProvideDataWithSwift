// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "BinaryStream",
    products: [
        .library(
            name: "BinaryStream",
            targets: ["BinaryStream"]),
    ],
    targets: [
        .target(
            name: "BinaryStream"),
        .testTarget(
            name: "BinaryStreamTests",
            dependencies: ["BinaryStream"]),
    ]
)
