//
//  AccessLevelTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 23/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import UIKit
import Testing
@testable import Baymax

@MainActor
@Suite("Access levels in Live builds", .serialized)
struct AccessLevelTests {

    private struct StubTool: DiagnosticTool {
        var displayName: String { "Stub" }
        func launchUI(in navigationController: UINavigationController) {}
    }

    private struct OpenProvider: DiagnosticsServiceProvider {
        var serviceName: String { "Open" }
        var diagnosticTools: [DiagnosticTool] { [StubTool()] }
        var access: DiagnosticAccess { .open }
    }

    /// Declares no `access`, so it gets the default.
    private struct UndeclaredProvider: DiagnosticsServiceProvider {
        var serviceName: String { "Undeclared" }
        var diagnosticTools: [DiagnosticTool] { [StubTool()] }
    }

    private func manager(isLive: Bool, isSimulator: Bool) -> DiagnosticsManager {
        let manager = DiagnosticsManager(isSimulator: isSimulator)
        manager.isLive = isLive
        manager.register(provider: OpenProvider())
        manager.register(provider: UndeclaredProvider())
        return manager
    }

    private func names(in manager: DiagnosticsManager) -> [String] {
        manager.diagnosticProviders.map(\.serviceName)
    }

    // MARK: - Defaults

    @Test("A build is treated as Live unless the app says otherwise")
    func liveByDefault() {
        #expect(DiagnosticsManager().isLive)
    }

    @Test("A provider that declares no access is locked")
    func lockedByDefault() {
        #expect(UndeclaredProvider().access == .locked)
    }

    // MARK: - Visibility

    @Test(
        "Outside a Live build on a device, every provider is listed",
        arguments: [(false, false), (false, true), (true, true)]
    )
    func everythingListed(isLive: Bool, isSimulator: Bool) {
        let manager = manager(isLive: isLive, isSimulator: isSimulator)

        #expect(names(in: manager) == ["Open", "Undeclared"])
    }

    @Test("A Live build on a device lists only open providers")
    func onlyOpenOnLiveDevice() {
        let manager = manager(isLive: true, isSimulator: false)

        #expect(names(in: manager) == ["Open"])
    }

    @Test("A hidden provider stays hidden even when it's open")
    func hiddenWinsOverOpen() {
        let manager = manager(isLive: true, isSimulator: false)
        manager.hide(provider: OpenProvider.self)

        #expect(manager.diagnosticProviders.isEmpty)
    }

    // MARK: - Built-in providers

    @Test("App & device is open, General is locked")
    func builtInAccess() {
        #expect(AppInfoServices().access == .open)
        #expect(BaymaxServices().access == .locked)
    }

    @Test("A Live build on a device lists only App & device from the built-ins")
    func builtInsOnLiveDevice() {
        let manager = DiagnosticsManager(isSimulator: false)
        manager.attach(to: UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100)))

        #expect(names(in: manager) == ["App & device"])
    }

    // MARK: - Empty state

    private func menuShowsEmptyState(for manager: DiagnosticsManager) -> Bool {
        let menu = DiagnosticsMenuTableViewController(manager: manager)
        menu.loadViewIfNeeded()
        menu.updateContentUnavailableConfiguration(
            using: UIContentUnavailableConfigurationState(traitCollection: menu.traitCollection)
        )
        return menu.contentUnavailableConfiguration != nil
    }

    @Test("The menu shows the empty state when nothing is listed")
    func emptyStateWhenNothingListed() {
        let manager = manager(isLive: true, isSimulator: false)
        manager.hide(provider: OpenProvider.self)

        #expect(menuShowsEmptyState(for: manager))
    }

    @Test("The menu has no empty state when something is listed")
    func noEmptyStateWhenListed() {
        #expect(!menuShowsEmptyState(for: manager(isLive: true, isSimulator: false)))
    }
}
