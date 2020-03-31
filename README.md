# Baymax

Baymax is a diagnostics tool for iOS apps which allows you and 3rd party frameworks to provide diagnostics via a shared interface.

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is the our suggested method for including Baymax into your iOS project or framework. Carthage is a package manager which either builds projects and provides you with binaries or uses pre-built frameworks from release tags in GitHub. To add Baymax to your project, simply specify it in your `Cartfile`:

```ogdl
github "3sidedcube/Baymax" ~> 1.0.0
```

## Usage

### Attaching Baymax to your window

Baymax must be attached to your app window in order to display UI when the user performs (currently) a 4 finger swipe upwards on the device:

```swift
DiagnosticsManager.shared.attach(to: myWindow)
```

the function accepts a window object, and an optional closure which can be used to provide a login mechanism for accessing Baymax's UI for the case where you might not want users to be able to access your diagnostics tools.

### Registering a set of diagnostic tools

To register yourself as a diagnostics provider, you need to conform to the
`DiagnosticsServiceProvider` and then call:

```swift
DiagnosticsManager.sharedInstance.register(provider: myProvider)
```


