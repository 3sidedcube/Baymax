//
//  DiagnosticsManagerAttachTests.swift
//  BaymaxTests
//
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI
import Testing
@testable import Baymax

@MainActor
@Suite("Attaching Baymax", .serialized)
struct DiagnosticsManagerAttachTests {

    private func swipeGestureCount(on window: UIWindow) -> Int {
        (window.gestureRecognizers ?? []).filter { $0 is UISwipeGestureRecognizer }.count
    }

    private func baymaxServicesCount(in manager: DiagnosticsManager) -> Int {
        manager.diagnosticProviders.filter { $0 is BaymaxServices }.count
    }

    @Test("Not attached until attach(to:) is called")
    func notAttachedInitially() {
        #expect(!DiagnosticsManager().isAttached)
    }

    @Test("Attaching twice to the same window registers once and adds one gesture")
    func attachTwiceSameWindow() {
        let manager = DiagnosticsManager()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        manager.attach(to: window)
        manager.attach(to: window)

        #expect(manager.isAttached)
        #expect(baymaxServicesCount(in: manager) == 1)
        #expect(swipeGestureCount(on: window) == 1)
    }

    @Test("Attaching to a new window moves the gesture")
    func attachMovesGesture() {
        let manager = DiagnosticsManager()
        let first = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let second = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        manager.attach(to: first)
        manager.attach(to: second)

        #expect(swipeGestureCount(on: first) == 0)
        #expect(swipeGestureCount(on: second) == 1)
        #expect(baymaxServicesCount(in: manager) == 1)
    }

    // MARK: - SwiftUI modifier

    private func host(probeEnabled: Bool, manager: DiagnosticsManager) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let content = Color.clear.background {
            if probeEnabled {
                BaymaxWindowProbe(manager: manager)
            }
        }
        window.rootViewController = UIHostingController(rootView: content)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return window
    }

    @Test("Probe attaches to the window it lands in")
    func probeAttaches() {
        let manager = DiagnosticsManager()

        let window = host(probeEnabled: true, manager: manager)

        #expect(manager.isAttached)
        #expect(swipeGestureCount(on: window) == 1)
    }

    @Test("Disabled modifier never attaches")
    func disabledDoesNotAttach() {
        let manager = DiagnosticsManager()

        _ = host(probeEnabled: false, manager: manager)

        #expect(!manager.isAttached)
    }

    @Test("Probe leaves an existing attachment alone")
    func probeKeepsExistingAttachment() {
        let manager = DiagnosticsManager()
        let original = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        manager.attach(to: original)

        let probed = host(probeEnabled: true, manager: manager)

        #expect(swipeGestureCount(on: original) == 1)
        #expect(swipeGestureCount(on: probed) == 0)
    }
}
