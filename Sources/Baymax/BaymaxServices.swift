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
        return [AppInfoTool(), UserDefaultsTool(), PropertyListTool(), LogsTool()]
    }
}
