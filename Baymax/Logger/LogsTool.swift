//
//  LogsTool.swift
//  Baymax
//
//  Created by Simon Mitchell on 01/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A tool for displaying logs collated using `Logger` objects
public class LogsTool: DiagnosticTool {
    
    public var displayName: String {
        return "Logs"
    }
    
    public func launchUI(in navigationController: UINavigationController) {
        let view = LogsTableViewController(style: .grouped)
        navigationController.show(view, sender: self)
    }
}
