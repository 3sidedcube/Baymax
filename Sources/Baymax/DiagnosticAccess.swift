//
//  DiagnosticAccess.swift
//  Baymax
//
//  Created by Szuyun Liang on 23/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

/// Whether a provider's tools are shown in a Live build on a real device.
public enum DiagnosticAccess {

    /// Shown everywhere, Live builds included.
    ///
    /// - Important: Anyone holding a Live user's phone can open Baymax. Only open a provider whose tools are
    ///   read-only and safe for them to see: never tokens, keys, logs, personal data, or anything that edits state.
    case open

    /// Hidden in Live builds on a real device. Shown in non-Live builds and on the Simulator.
    case locked
}
