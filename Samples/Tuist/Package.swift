// swift-tools-version: 5.9

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "KeyboardObserver": .framework,
    ]
)
#endif

let package = Package(
    name: "Development",
    dependencies: [
        .package(path: "../../"),
    ]
)
