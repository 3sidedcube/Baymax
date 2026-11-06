//
//  FirebaseDebugViewToolTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation
import Testing
@testable import Baymax

@Suite("GA DebugView tool", .serialized)
struct FirebaseDebugViewToolTests {

    private let suiteName = "BaymaxTests.FirebaseDebugView"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Uses the keys -FIRDebugEnabled writes and GoogleAppMeasurement reads")
    func keys() {
        #expect(FirebaseDebugViewTool.keys == ["/google/firebase/debug_mode", "/google/measurement/debug_mode"])
    }

    @Test("Turning on sets both keys")
    func enableSetsKeys() {
        FirebaseDebugViewTool.setEnabled(true, in: defaults)

        #expect(defaults.bool(forKey: "/google/firebase/debug_mode"))
        #expect(defaults.bool(forKey: "/google/measurement/debug_mode"))
        #expect(FirebaseDebugViewTool.isEnabled(in: defaults))
    }

    @Test("Turning off removes both keys, as -FIRDebugDisabled does")
    func disableRemovesKeys() {
        FirebaseDebugViewTool.setEnabled(true, in: defaults)

        FirebaseDebugViewTool.setEnabled(false, in: defaults)

        #expect(defaults.object(forKey: "/google/firebase/debug_mode") == nil)
        #expect(defaults.object(forKey: "/google/measurement/debug_mode") == nil)
        #expect(!FirebaseDebugViewTool.isEnabled(in: defaults))
    }

    @Test("Only on when both keys are set")
    func partialIsOff() {
        defaults.set(true, forKey: "/google/firebase/debug_mode")

        #expect(!FirebaseDebugViewTool.isEnabled(in: defaults))
    }

    @Test("Firebase isn't linked into the test bundle")
    func firebaseAbsentInTests() {
        #expect(!FirebaseDebugViewTool.isFirebasePresent)
        #expect(!BaymaxServices().diagnosticTools.contains { $0 is FirebaseDebugViewTool })
    }

    @Test("Listed after UserDefaults when Firebase is present")
    func listedWhenFirebasePresent() {
        let tools = BaymaxServices.tools(includingFirebase: true)

        #expect(tools.map(\.displayName) == ["App & device info", "UserDefaults", "GA DebugView", "Property List Viewer", "Logs"])
    }

    @Test("Not listed when Firebase is absent")
    func notListedWhenFirebaseAbsent() {
        let tools = BaymaxServices.tools(includingFirebase: false)

        #expect(tools.map(\.displayName) == ["App & device info", "UserDefaults", "Property List Viewer", "Logs"])
    }
}
