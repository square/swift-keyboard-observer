import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: "KeyboardObserverDevelopment",
    projects: ["."],
    schemes: [
        .keyboardObserver("KeyboardObserver"),
    ]
)

extension Scheme {
    public static func keyboardObserver(_ target: String) -> Self {
        .scheme(
            name: target,
            buildAction: .buildAction(targets: [.project(path: "..", target: target)])
        )
    }
}
