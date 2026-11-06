//
//  UIWindow+Shake.swift
//  Baymax
//
//  Created by Szuyun Liang on 06/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import UIKit

#if targetEnvironment(simulator)
extension UIWindow {

    /// Simulator only: a shake (Device › Shake, ⌃⌘Z) shows or hides the entry controls.
    /// Shakes reach the window through the responder chain unless something before it handles them,
    /// which is the one place Baymax can see them without app code.
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            DiagnosticsManager.shared.handleShake()
        }
        super.motionEnded(motion, with: event)
    }
}
#endif
