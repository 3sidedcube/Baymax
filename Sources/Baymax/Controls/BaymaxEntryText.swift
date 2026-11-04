//
//  BaymaxEntryText.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

/// Text shared by the entry controls (`BaymaxRow`, `baymaxButton()`), so they read the same.
enum BaymaxEntryText {

    /// Row title
    static let title = "Diagnostics"

    /// Baymax's face, used as the controls' icon
    static let ascii = "●---●"

    /// VoiceOver label for every control
    static let accessibilityLabel = "Open diagnostics"
}
