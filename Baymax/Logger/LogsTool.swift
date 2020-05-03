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
    
    /// Disables or enables Baymax logging
    public static var loggingEnabled: Bool {
        get {
            return UserDefaults.standard.baymaxLoggingEnabled
        }
        set {
            UserDefaults.standard.baymaxLoggingEnabled = newValue
        }
    }
    
    /// Instructs Baymax logging to either be on or off by default,
    /// defaults to `false`
    public static var loggingEnabledByDefault: Bool = false
    
    /// Can be provided to override how logs are shared by default
    ///
    /// You will be handed an array of log files, and the sender if you return false, indicating
    /// that you weren't able to share them, then they will continue to be shared
    /// using the default mechanism!
    public static var shareHandler: (([LogFile], Any) -> Bool)?
    
    public var displayName: String {
        return "Logs"
    }
    
    public func launchUI(in navigationController: UINavigationController) {
        let view = LogsTableViewController(style: .grouped)
        navigationController.show(view, sender: self)
    }
}
