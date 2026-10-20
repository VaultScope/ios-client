// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UserApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "UserApp",
            targets: ["UserApp"]
        ),
    ],
    targets: [
        .target(
            name: "UserApp",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
