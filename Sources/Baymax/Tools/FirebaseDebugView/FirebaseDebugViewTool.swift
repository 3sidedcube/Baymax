//
//  FirebaseDebugViewTool.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Turns Firebase Analytics DebugView on or off without launch arguments, so TestFlight builds can use it.
/// Built in, in the "General" section, and only listed when Firebase is in the app.
///
/// It writes the UserDefaults keys that `-FIRDebugEnabled` / `-FIRDebugDisabled` write. They're undocumented,
/// so a Firebase update could change them; re-check after upgrading the Firebase SDK.
public struct FirebaseDebugViewTool: SwiftUIDiagnosticTool {

    /// `/google/firebase/debug_mode`: written by `-FIRDebugEnabled` (FirebaseCore `FIRLogger.m`).
    /// `/google/measurement/debug_mode`: read by GoogleAppMeasurement, which drives DebugView.
    static let keys = ["/google/firebase/debug_mode", "/google/measurement/debug_mode"]

    /// Whether Firebase is linked into the app. Checked by class name, so Baymax doesn't depend on Firebase.
    static var isFirebasePresent: Bool {
        NSClassFromString("FIRApp") != nil
    }

    /// On only when both keys are set, matching what `-FIRDebugEnabled` leaves behind.
    static func isEnabled(in defaults: UserDefaults = .standard) -> Bool {
        keys.allSatisfy { defaults.bool(forKey: $0) }
    }

    /// Sets both keys, or removes them (as `-FIRDebugDisabled` does). Firebase reads them only at launch.
    static func setEnabled(_ enabled: Bool, in defaults: UserDefaults = .standard) {
        for key in keys {
            if enabled {
                defaults.set(true, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    public init() {}

    public var displayName: String {
        return "GA DebugView"
    }

    public func makeView() -> some View {
        FirebaseDebugViewScreen()
    }
}

/// The DebugView switch, with the relaunch reminder and the unofficial-keys note.
private struct FirebaseDebugViewScreen: View {

    @State private var isEnabled = FirebaseDebugViewTool.isEnabled()
    @State private var hasChanged = false

    var body: some View {
        Form {
            Section {
                Toggle("Analytics DebugView", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        FirebaseDebugViewTool.setEnabled(newValue)
                        isEnabled = newValue
                        hasChanged = true
                    }
                ))
            } footer: {
                if hasChanged {
                    Label("Relaunch the app to apply.", systemImage: "arrow.clockwise")
                } else {
                    Text("Sends this device's Analytics events to DebugView in the Firebase console, like the -FIRDebugEnabled launch argument.")
                }
            }

            Section {
                EmptyView()
            } footer: {
                Text("Unofficial: relies on undocumented Firebase keys. Re-check after Firebase SDK upgrades.")
            }
        }
    }
}
