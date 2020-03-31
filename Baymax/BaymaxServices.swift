//
//  BaymaxServices.swift
//  Baymax
//
//  Created by Matthew Cheetham on 12/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

class BaymaxServices: DiagnosticsServiceProvider {
    
    var serviceName: String {
        return "General"
    }
    
    var diagnosticTools: [DiagnosticTool] {
        return [PropertyListTool()]
    }
}
