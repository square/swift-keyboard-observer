import Foundation
import ProjectDescription

public let keyboardObserverBundleIdPrefix = "com.squareup.keyboard-observer"
public let keyboardObserverDestinations: ProjectDescription.Destinations = .iOS
public let keyboardObserverDeploymentTargets: DeploymentTargets = .iOS("15.0")

extension Target {
    public static func app(
        name: String,
        sources: ProjectDescription.SourceFilesList,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: name,
            destinations: keyboardObserverDestinations,
            product: .app,
            bundleId: "\(keyboardObserverBundleIdPrefix).\(name)",
            deploymentTargets: keyboardObserverDeploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": ["UIColorName": ""],
                ]
            ),
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func target(
        name: String,
        sources: ProjectDescription.SourceFilesList? = nil,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: name,
            destinations: keyboardObserverDestinations,
            product: .framework,
            bundleId: "\(keyboardObserverBundleIdPrefix).\(name)",
            deploymentTargets: keyboardObserverDeploymentTargets,
            sources: sources ?? "\(name)/Sources/**",
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func unitTest(
        for moduleUnderTest: String,
        testName: String = "Tests",
        sources: ProjectDescription.SourceFilesList? = nil,
        dependencies: [TargetDependency] = [],
        environmentVariables: [String: EnvironmentVariable] = [:]
    ) -> Self {
        let name = "\(moduleUnderTest)-\(testName)"
        return .target(
            name: name,
            destinations: keyboardObserverDestinations,
            product: .unitTests,
            bundleId: "\(keyboardObserverBundleIdPrefix).\(name)",
            deploymentTargets: keyboardObserverDeploymentTargets,
            sources: sources ?? "../\(moduleUnderTest)/\(testName)/**",
            dependencies: [.external(name: moduleUnderTest)] + dependencies,
            environmentVariables: environmentVariables
        )
    }
}
