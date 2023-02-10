//
//  DiagnosticsServiceProtocol.swift
//  Baymax
//
//  Created by Matthew Cheetham on 08/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import UIKit

public protocol DiagnosticTool {
    
    /// Name of the tool to display in a list of tools
    var displayName: String { get }
    
    /// Called when the tool is activated. You must use this to present your tool's UI on the navigation stack.
    ///
    /// - Parameter navigationController: The navigation controller that can be used to present or push the view
    func launchUI(in navigationController: UINavigationController)
}
