# Baymax

[![Build Status](https://travis-ci.org/3sidedcube/Baymax.svg)](https://travis-ci.org/3sidedcube/Baymax) [![Swift 5.5](http://img.shields.io/badge/swift-5.5-brightgreen.svg)](https://swift.org/blog/swift-5-5-released/) [![Apache 2](https://img.shields.io/badge/license-GNU%20General%20Public%20License%20v3.0-brightgreen.svg)](LICENSE.md)

Baymax is a diagnostics tool for iOS apps which allows you and 3rd party frameworks to provide diagnostics via a shared interface.

# Installation

Add the package with Swift Package Manager, either in Xcode (File › Add Package Dependencies…) or in a `Package.swift`:

```swift
.package(url: "https://github.com/3sidedcube/Baymax.git", from: "27.1.0")
```

`Baymax` is a dynamic library product. Add it to your app target with **Embed & Sign**; other targets that use it (frameworks, app extensions, test bundles) link it without embedding, so the app loads a single copy.

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

### SwiftUI tools

Conform to `SwiftUIDiagnosticTool` instead and return your view from `makeView()`. Baymax hosts it and pushes it for you, titled with `displayName`, so there's no need to implement `launchUI`:

```swift
struct FeatureFlagsTool: SwiftUIDiagnosticTool {
    var displayName: String { "Feature flags" }
    func makeView() -> some View { FeatureFlagsScreen() }
}
```

SwiftUI tools go in `diagnosticTools` alongside UIKit ones.

## SwiftUI apps

Apps without a UIKit window to pass to `attach(to:)` can attach Baymax from their root view:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .baymaxDiagnostics(enabled: showDebug)
        }
    }
}
```

Pass `enabled: false` (e.g. in production builds) to never attach Baymax. The modifier does nothing if Baymax is already attached, and attaches to the first window it appears in.

`attach(to:)` itself is safe to call more than once, and `DiagnosticsManager.shared.isAttached` reports whether Baymax is attached.

## Opening Baymax without the gesture

Some environments can't perform the multi-finger swipe (e.g. Simulator-based device farms that only send single touches). Baymax ships SwiftUI controls that open it with one tap. Place them where they suit your app.

All of them:
- **are only shown on the Simulator.** They're always hidden on real devices, so they never appear in release builds; there, Baymax is opened with the multi-finger swipe gesture;
- **are hidden while Baymax isn't attached**, so they also disappear in builds that never call `attach(to:)`;
- **run the authentication handler** given to `attach(to:)`, if any, before showing Baymax.

| Control | Use when |
|---|---|
| `BaymaxRow()` | You have a plain `List` / `Form` (e.g. a Settings or More screen) |
| `BaymaxEntry { open in … }` | Your rows use your own design system |
| `.baymaxButton()` | You'd rather have a small draggable button on one screen |

```swift
// Plain row
List {
    ...
    BaymaxRow()
}

// Your own row component
BaymaxEntry { open in
    MyListItem(title: "Diagnostics", onTap: open)
}

// Floating button on one screen
MoreScreen()
    .baymaxButton()
```

## Logging

Baymax provides an alternative to Apple's `os_log` function, which will save logs to the user's documents directory, they will also be viewable using the Logs tool provided by default by baymax. The logger can be used like so:

```swift
baymax_log("App Launch", category: "App Lifecycle", type: .debug)
```
the function also supports providing a `subsystem` like the `os_log` function. This function will NOT also write to `os_log` so you should make sure you are still logging there if you want to utilise Apple's logging tools.

## Default Tools

### App & device info

Shows the app's name, version, build and bundle ID, and the device's model, iOS version, locale and time zone. Tap a row to copy its value, or use the share button to share everything as text, e.g. into a ticket or Slack.

Values only the app knows are recorded with `AppInfoTool.record(_:)`, whenever they change. Recording again replaces the earlier value (same token type, or same `custom` title):

```swift
// didRegisterForRemoteNotificationsWithDeviceToken
// (with Firebase Messaging swizzling and no such method, use Messaging.messaging().apnsToken)
AppInfoTool.record(.apnsToken(deviceToken: deviceToken))

// Firebase Cloud Messaging: messaging(_:didReceiveRegistrationToken:)
AppInfoTool.record(.fcmToken(fcmToken))

// Anything else
AppInfoTool.record(.custom(title: "Environment", value: "dev"))
```

Values Baymax should fetch itself are supplied with `AppInfoTool.provide(_:)`. The closure runs only when the tool opens, never at launch, and its values replace recorded ones with the same identity. For example, the App Check token Firebase currently holds (only its expiry is shown, never the token):

```swift
AppInfoTool.provide {
    guard let token = try? await AppCheck.appCheck().token(forcingRefresh: false) else { return [] }
    return [.appCheckToken(token.token)]
}
```

`forcingRefresh: false` returns Firebase's saved token while it's valid; once it has expired, Firebase creates a new one.

### UserDefaults

Lists the app's own UserDefaults keys, with search. Apple's global keys are in a read-only "System keys" section at the bottom, folded by default. Strings, numbers, bools and dates can be edited, and keys deleted with a swipe. Arrays and dictionaries open as a list of their items, which can be edited or deleted at any depth; changes are kept until Save, and Cancel discards them. Data values are read-only.

Protect keys that an edit would corrupt or that would break the app, such as encrypted values or device identifiers. Protected keys are shown with a lock and can't be edited or deleted:

```swift
UserDefaultsTool.protectedKeys = ["authorizationCredentials", "persistedDeviceID"]
```

Some apps read values only at launch, so a change may need a relaunch to take effect.

### GA DebugView

Only listed when Firebase is in the app. A switch turns Firebase Analytics DebugView on or off without the `-FIRDebugEnabled` launch argument, so it works on TestFlight builds. Relaunch the app afterwards, because Firebase reads the setting only at launch. Baymax doesn't depend on Firebase: the switch writes the UserDefaults keys the launch argument writes (`/google/firebase/debug_mode`, `/google/measurement/debug_mode`). These keys are undocumented, so re-check the tool after Firebase SDK upgrades.

### Logging

The logging tool allows you to view, share and delete logs created by calling `baymax_log` or manually using a `Logger` object.

### Property List Viewer

The property list viewer allows you to view the contents of your app's Info.plist!

