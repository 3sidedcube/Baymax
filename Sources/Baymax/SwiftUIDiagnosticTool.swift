//
//  SwiftUIDiagnosticTool.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// A `DiagnosticTool` whose UI is a SwiftUI view. Baymax hosts the view and pushes it,
/// titled with `displayName`, so the tool only has to describe its content.
public protocol SwiftUIDiagnosticTool: DiagnosticTool {

    associatedtype Content: View

    /// The tool's UI, shown when the user selects the tool.
    @MainActor @ViewBuilder
    func makeView() -> Content
}

extension SwiftUIDiagnosticTool {

    @MainActor
    public func launchUI(in navigationController: UINavigationController) {
        let hostingController = UIHostingController(rootView: makeView())
        hostingController.title = displayName
        navigationController.pushViewController(hostingController, animated: true)
    }
}
