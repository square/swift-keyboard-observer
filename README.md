# KeyboardObserver

[![Validations](https://github.com/square/swift-keyboard-observer/actions/workflows/validations.yaml/badge.svg)](https://github.com/square/swift-keyboard-observer/actions/workflows/validations.yaml)

A lightweight framework for observing the keyboard frame on iOS and iPadOS.

KeyboardObserver listens for system keyboard notifications, converts the keyboard's visible frame into the coordinate space of any view, and notifies delegates with animation metadata so that UI updates can be synchronized with keyboard transitions.

## Features

- Tracks keyboard frame changes via both `willChangeFrame` and `didChangeFrame` notifications for comprehensive coverage.
- Converts keyboard frames from screen coordinates to any view's local coordinate space.
- Supports detecting floating iPad keyboards.
- Provides animation duration and curve for synchronized UI updates.

## Getting Started

### Swift Package Manager

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)

Add KeyboardObserver as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/square/swift-keyboard-observer", from: "1.0.0")
]
```

### Usage

Configure the shared observer at app startup to ensure no keyboard events are missed:

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    KeyboardObserver.configure(with: application)
    // ...
}
```

Implement `KeyboardObserverDelegate` to respond to keyboard changes:

```swift
class MyViewController: UIViewController, KeyboardObserverDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardObserver.shared.add(delegate: self)
    }

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    ) {
        let frame = observer.currentFrame(in: view)

        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
            // Update layout based on frame
        }
        animator.startAnimation()
    }
}
```

Some sample code is available in the [Samples](Samples) directory. To build the sample code, use the local development instructions below.

## Local Development

This project uses [Mise](https://mise.jdx.dev/) and [Tuist](https://tuist.io/) to generate a project for local development. Follow the steps below for the recommended setup for zsh.

```sh
# install mise
brew install mise
# add mise activation line to your zshrc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# load mise into your shell
source ~/.zshrc
# tell mise to trust this repo's config file
mise trust
# install dependencies
mise install

# only necessary for first setup or after changing dependencies
tuist install --path Samples
# generates and opens the Xcode project
tuist generate --path Samples
```

## License

```plaintext
Copyright 2026 Block Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
