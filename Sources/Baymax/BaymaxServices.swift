//
//  BaymaxServices.swift
//  Baymax
//
//  Created by Matthew Cheetham on 12/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// The services provided by Baymax by default
public class BaymaxServices: DiagnosticsServiceProvider {

    public var serviceName: String {
        return "General"
    }

    public var diagnosticTools: [DiagnosticTool] {
        return Self.tools(includingFirebase: FirebaseDebugViewTool.isFirebasePresent)
    }

    /// The built-in tools, in order. The GA DebugView tool only appears when Firebase is in the app.
    static func tools(includingFirebase: Bool) -> [DiagnosticTool] {
        let firebaseTools: [DiagnosticTool] = includingFirebase ? [FirebaseDebugViewTool()] : []
        return [AppInfoTool(), UserDefaultsTool()] + firebaseTools + [PropertyListTool(), LogsTool()]
    }
}
