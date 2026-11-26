//
//  View+Baymax.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

extension View {

    /// Attaches Baymax to the window this view is shown in, for apps without a UIKit
    /// window to pass to `DiagnosticsManager.attach(to:)`. Apply it to the root view.
    ///
    /// If Baymax is already attached (by the app or an earlier use of this modifier),
    /// this does nothing, so an existing authentication handler is never replaced.
    ///
    /// - Parameters:
    ///   - enabled: Pass `false` (e.g. in production builds) to never attach Baymax.
    ///   - authenticationHandler: Optional login gate, as in `attach(to:authenticationHandler:)`.
    public func baymaxDiagnostics(
        enabled: Bool,
        authenticationHandler: DiagnosticsManager.AuthenticationRequestClosure? = nil
    ) -> some View {
        background {
            if enabled {
                BaymaxWindowProbe(authenticationHandler: authenticationHandler)
            }
        }
    }
}

/// Invisible view that attaches Baymax once it lands in a window.
struct BaymaxWindowProbe: UIViewRepresentable {

    var manager: DiagnosticsManager = .shared
    var authenticationHandler: DiagnosticsManager.AuthenticationRequestClosure?

    func makeUIView(context: Context) -> ProbeView {
        ProbeView(manager: manager, authenticationHandler: authenticationHandler)
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    final class ProbeView: UIView {

        private let manager: DiagnosticsManager
        private let authenticationHandler: DiagnosticsManager.AuthenticationRequestClosure?

        init(manager: DiagnosticsManager, authenticationHandler: DiagnosticsManager.AuthenticationRequestClosure?) {
            self.manager = manager
            self.authenticationHandler = authenticationHandler
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, !manager.isAttached else { return }
            manager.attach(to: window, authenticationHandler: authenticationHandler)
        }
    }
}
