//
//  EntryControlsTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Testing
import UIKit
@testable import Baymax

@MainActor
@Suite("Entry controls", .serialized)
struct EntryControlsTests {

    private func makeWindow() -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        return window
    }

    private func presentedMenu(in window: UIWindow) -> Bool {
        let navigationController = window.rootViewController?.presentedViewController as? UINavigationController
        return navigationController?.viewControllers.first is DiagnosticsMenuTableViewController
    }

    // MARK: - Attachment notification

    @Test("Posted once on the first attach only")
    func notificationPostedOnFirstAttach() {
        let manager = DiagnosticsManager()
        var posts = 0
        let observer = NotificationCenter.default.addObserver(
            forName: DiagnosticsManager.attachmentDidChangeNotification,
            object: manager,
            queue: nil
        ) { _ in posts += 1 }
        defer { NotificationCenter.default.removeObserver(observer) }

        let window = makeWindow()
        manager.attach(to: window)
        manager.attach(to: window)
        manager.attach(to: makeWindow())

        #expect(posts == 1)
    }

    // MARK: - requestPresentation

    @Test("Does nothing when not attached")
    func requestPresentationNotAttached() {
        let manager = DiagnosticsManager()
        let window = makeWindow()

        manager.requestPresentation()

        #expect(window.rootViewController?.presentedViewController == nil)
    }

    @Test("Presents directly without an auth handler")
    func requestPresentationWithoutAuth() {
        let manager = DiagnosticsManager()
        let window = makeWindow()
        manager.attach(to: window)

        manager.requestPresentation()

        #expect(presentedMenu(in: window))
    }

    @Test("Runs the auth handler first, presenting only when approved", arguments: [true, false])
    func requestPresentationWithAuth(approved: Bool) {
        let manager = DiagnosticsManager()
        let window = makeWindow()
        var authRequested = false
        manager.attach(to: window) { completion in
            authRequested = true
            completion(approved)
        }

        manager.requestPresentation()

        #expect(authRequested)
        #expect(presentedMenu(in: window) == approved)
    }

    // MARK: - BaymaxEntry state

    @Test("Entry state follows attachment")
    func attachmentStateUpdates() {
        let manager = DiagnosticsManager()
        let state = AttachmentState(manager: manager)
        #expect(!state.isAttached)

        manager.attach(to: makeWindow())

        #expect(state.isAttached)
    }

    @Test("Entry state starts attached if Baymax already is")
    func attachmentStateInitiallyAttached() {
        let manager = DiagnosticsManager()
        manager.attach(to: makeWindow())

        #expect(AttachmentState(manager: manager).isAttached)
    }

    @Test("Entry open action presents through the manager")
    func attachmentStateOpens() {
        let manager = DiagnosticsManager()
        let window = makeWindow()
        manager.attach(to: window)

        AttachmentState(manager: manager).open()

        #expect(presentedMenu(in: window))
    }

    // MARK: - Floating button

    @Test("Floating button stays inside the container with a margin")
    func floatingButtonClamps() {
        let button = BaymaxFloatingButton(manager: DiagnosticsManager())
        let size = CGSize(width: 300, height: 600)
        let inset: CGFloat = 16 + 22

        #expect(button.clamped(CGPoint(x: -50, y: -50), in: size) == CGPoint(x: inset, y: inset))
        #expect(button.clamped(CGPoint(x: 999, y: 999), in: size) == CGPoint(x: 300 - inset, y: 600 - inset))
        #expect(button.clamped(CGPoint(x: 150, y: 300), in: size) == CGPoint(x: 150, y: 300))
    }
}
