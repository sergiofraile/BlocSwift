// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bloc",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
        ],
    products: [
        .library(
            name: "Bloc",
            targets: ["Bloc"]
        ),
    ],
    targets: [
        .target(
            name: "Bloc"
        ),
        .testTarget(
            name: "BlocTests",
            dependencies: ["Bloc"]
        ),
    ]
)
