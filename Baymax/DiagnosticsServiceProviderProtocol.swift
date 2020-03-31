//
//  DiagnosticsServiceProviderProtocol.swift
//  Baymax
//
//  Created by Matthew Cheetham on 08/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// Displayed as a table section. This is the top level object for the group of tools you are providing.
public protocol DiagnosticsServiceProvider {
        
    /// The name of the service this set of tools is for.
    var serviceName: String { get }
    
    /// An array of services (or tools)
    var diagnosticTools: [DiagnosticTool] { get }
}
