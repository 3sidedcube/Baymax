//
//  PlistEditingTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation
import Testing
@testable import Baymax

@Suite("Editing array and dictionary items")
struct PlistEditingTests {

    private let root: Any = [
        "name": "Baymax",
        "tags": ["a", "b", "c"],
        "nested": ["count": 1, "list": [10, 20]]
    ] as [String: Any]

    @Test("Lists array items in order and dictionary items by key")
    func children() {
        #expect(PlistEditing.children(of: ["x", "y"]).map(\.component) == [.index(0), .index(1)])
        #expect(PlistEditing.children(of: root).map(\.component) == [.key("name"), .key("nested"), .key("tags")])
        #expect(PlistEditing.children(of: "not a container").isEmpty)
    }

    @Test("Reads a value at any depth")
    func readsNested() {
        #expect(PlistEditing.value(at: [.key("nested"), .key("list"), .index(1)], in: root) as? Int == 20)
        #expect(PlistEditing.value(at: [.key("missing")], in: root) == nil)
    }

    @Test("Replaces a dictionary value and an array item at depth")
    func setsNested() {
        var updated = PlistEditing.setting("Hiro", at: [.key("name")], in: root)
        updated = PlistEditing.setting(99, at: [.key("nested"), .key("list"), .index(0)], in: updated)

        #expect(PlistEditing.value(at: [.key("name")], in: updated) as? String == "Hiro")
        #expect(PlistEditing.value(at: [.key("nested"), .key("list")], in: updated) as? [Int] == [99, 20])
    }

    @Test("Removes array items and dictionary keys at depth")
    func removesNested() {
        var updated = PlistEditing.removing(at: [.key("tags"), .index(1)], in: root)
        updated = PlistEditing.removing(at: [.key("nested"), .key("count")], in: updated)

        #expect(PlistEditing.value(at: [.key("tags")], in: updated) as? [String] == ["a", "c"])
        #expect((PlistEditing.value(at: [.key("nested")], in: updated) as? [String: Any])?.keys.sorted() == ["list"])
    }

    @Test("A path that doesn't exist leaves the value unchanged")
    func missingPathUnchanged() {
        let set = PlistEditing.setting(1, at: [.key("tags"), .index(9)], in: root)
        let removed = PlistEditing.removing(at: [.key("missing"), .index(0)], in: root)

        #expect(!PlistEditing.differs(set, root))
        #expect(!PlistEditing.differs(removed, root))
    }

    @Test("Detects deep differences")
    func differs() {
        let changed = PlistEditing.setting(21, at: [.key("nested"), .key("list"), .index(1)], in: root)

        #expect(PlistEditing.differs(changed, root))
        #expect(!PlistEditing.differs(root, root))
    }

    @Test("Parses numbers as Int or Double")
    func parsesNumbers() {
        #expect(PlistEditing.parseNumber(" 42 ", integer: true) as? Int == 42)
        #expect(PlistEditing.parseNumber("1.5", integer: true) == nil)
        #expect(PlistEditing.parseNumber("1.5", integer: false) as? Double == 1.5)
        #expect(PlistEditing.parseNumber("abc", integer: false) == nil)
    }
}
