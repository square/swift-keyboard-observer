import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "KeyboardObserverDevelopment",
    settings: .settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
    targets: [

        .app(
            name: "DemoApp",
            sources: "DemoApp/Sources/**",
            dependencies: [
                .external(name: "KeyboardObserver"),
            ]
        ),

        .app(
            name: "TestAppHost",
            sources: "../TestingSupport/AppHost/Sources/**",
            dependencies: [
                .external(name: "KeyboardObserver"),
            ]
        ),

        .unitTest(
            for: "KeyboardObserver",
            dependencies: [
                .target(name: "TestAppHost"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "UnitTests",
            testAction: .targets(
                [
                    "KeyboardObserver-Tests",
                ]
            )
        ),
        .scheme(
            name: "Samples",
            buildAction: .buildAction(
                targets: [
                    "DemoApp",
                ]
            )
        ),
    ]
)
