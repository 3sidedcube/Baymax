//
//  AppInfoServices.swift
//  Baymax
//
//  Created by Szuyun Liang on 23/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// Baymax's "App & device" section. Open, so Live builds show it; the tool drops app-supplied values there.
public class AppInfoServices: DiagnosticsServiceProvider {

    public var serviceName: String {
        return "App & device"
    }

    public var diagnosticTools: [DiagnosticTool] {
        return [AppInfoTool()]
    }

    public var access: DiagnosticAccess {
        return .open
    }
}
