//
//  SwiftUIToolTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI
import Testing
@testable import Baymax

private struct SampleSwiftUITool: SwiftUIDiagnosticTool {
    var displayName: String { "Sample SwiftUI" }
    func makeView() -> some View { Text("Hello") }
}

private final class SampleUIKitTool: DiagnosticTool {
    let pushed = UIViewController()
    var displayName: String { "Sample UIKit" }
    func launchUI(in navigationController: UINavigationController) {
        navigationController.pushViewController(pushed, animated: false)
    }
}

@MainActor
@Suite("SwiftUI diagnostic tools")
struct SwiftUIToolTests {

    private func makeNavigationController() -> UINavigationController {
        UINavigationController(rootViewController: UIViewController())
    }

    @Test("Pushes a hosting controller titled with displayName")
    func pushesHostingController() throws {
        let navigationController = makeNavigationController()

        SampleSwiftUITool().launchUI(in: navigationController)

        let top = try #require(navigationController.topViewController)
        #expect(top is UIHostingController<Text>)
        #expect(top.title == "Sample SwiftUI")
        #expect(navigationController.viewControllers.count == 2)
    }

    @Test("Launches when stored as a DiagnosticTool existential")
    func launchesFromExistential() {
        let tools: [DiagnosticTool] = [SampleSwiftUITool()]
        let navigationController = makeNavigationController()

        tools[0].launchUI(in: navigationController)

        #expect(navigationController.topViewController is UIHostingController<Text>)
    }

    @Test("UIKit tools still push their own view controller")
    func uiKitToolUnchanged() {
        let tool = SampleUIKitTool()
        let navigationController = makeNavigationController()

        tool.launchUI(in: navigationController)

        #expect(navigationController.topViewController === tool.pushed)
    }
}
