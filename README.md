# Baymax

[![Build Status](https://travis-ci.org/3sidedcube/iOS-Baymax.svg)](https://travis-ci.org/3sidedcube/iOS-Baymax) [![Swift 5.3](http://img.shields.io/badge/swift-5.3-brightgreen.svg)](https://swift.org/blog/swift-5-3-released/) [![Apache 2](https://img.shields.io/badge/license-GNU%20General%20Public%20License%20v3.0-brightgreen.svg)](LICENSE.md)

Baymax is a diagnostics tool for iOS apps which allows you and 3rd party frameworks to provide diagnostics via a shared interface.

# Installation

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is the our suggested method for including Baymax into your iOS project or framework. Carthage is a package manager which either builds projects and provides you with binaries or uses pre-built frameworks from release tags in GitHub. To add Baymax to your project, simply specify it in your `Cartfile`:

```ogdl
github "3sidedcube/Baymax" ~> 1.0.0
```

# Usage

## Attaching Baymax to your window

Baymax must be attached to your app window in order to display UI when the user performs (currently) a 4 finger swipe upwards on the device:

```swift
DiagnosticsManager.shared.attach(to: myWindow)
```

the function accepts a window object, and an optional closure which can be used to provide a login mechanism for accessing Baymax's UI for the case where you might not want users to be able to access your diagnostics tools.

## Registering a set of diagnostic tools

### `DiagnosticServiceProvider` protocol

To register yourself as a diagnostics provider, you need to conform to the
`DiagnosticsServiceProvider` and then call:

```swift
DiagnosticsManager.sharedInstance.register(provider: myProvider)
```

`DiagnosticsServiceProvider` is a simple protocol which requires only two properties to be implemented:

#### `serviceName` (String)

This provides the readable name which will be displayed at the root level of Baymax's UI. It should represent your tool fairly so users know what each provider in baymax provides for them.

#### `diagnosticsTools` (Array\<DiagnosticTool\>)

This provides an array of tools, which will be rendered for selection when the user clicks the entry in the main UI for your service provider.

### `DiagnosticTool` protocol

`DiagnosticTool` is also a simple protocol with one property, and one function that need implementing:

#### `displayName` (String)

This provides the readable name that will be displayed in Baymax's UI once the user has clicked into your provider.

#### `launchUI` (Function)

`func launchUI(in navigationController: UINavigationController)`

`launchUI` function gets passed the current navigation controller that Baymax is using for it's UI, allowing you to push/present whatever UI you would like for your tool. This is called when the user clicks the table cell for an individual tool. 

## Logging

Baymax provides an alternative to Apple's `os_log` function, which will save logs to the user's documents directory, they will also be viewable using the Logs tool provided by default by baymax. The logger can be used like so:

```swift
baymax_log("App Launch", category: "App Lifecycle", type: .debug)
```
the function also supports providing a `subsystem` like the `os_log` function. This function will NOT also write to `os_log` so you should make sure you are still logging there if you want to utilise Apple's logging tools.

## Default Tools

### Logging

The logging tool allows you to view, share and delete logs created by calling `baymax_log` or manually using a `Logger` object.

### Property List Viewer

The property list viewer allows you to view the contents of your app's Info.plist!

# Building Binaries for Carthage

Since Xcode 12 there has been issues with building Carthage binaries caused by the inclusion of a secondary arm64 slice in the generated binary needed for Apple Silicon on macOS. This means that rather than simply using `carthage build --archive` you need to use the `./carthage-build build --archive` command which uses the script included with this repo. For more information, see the issue on Carthage's github [here](https://github.com/Carthage/Carthage/issues/3019)

We will be investigating moving over to use SPM as an agency soon, and will also look into migrating to use .xcframeworks as soon as Carthage have support for it.
