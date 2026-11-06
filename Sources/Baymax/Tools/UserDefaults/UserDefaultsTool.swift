//
//  UserDefaultsTool.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Views and edits the app's UserDefaults. Built in, in the "General" section.
public struct UserDefaultsTool: SwiftUIDiagnosticTool {

    /// Keys shown read-only and never deleted, e.g. encrypted values or device identifiers
    /// that an edit would corrupt or that would break the app.
    public static var protectedKeys: Set<String> = []

    public init() {}

    public var displayName: String {
        return "UserDefaults"
    }

    public func makeView() -> some View {
        UserDefaultsScreen(store: UserDefaultsStore(protectedKeys: Self.protectedKeys))
    }
}
