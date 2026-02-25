// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KeyboardObserver",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "KeyboardObserver",
            targets: ["KeyboardObserver"]
        ),
    ],
    targets: [
        .target(
            name: "KeyboardObserver",
            path: "KeyboardObserver",
            exclude: ["Tests"],
            sources: ["Sources"]
        ),
    ]
)
