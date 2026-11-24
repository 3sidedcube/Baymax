//
//  UserDefaultsStoreTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation
import Testing
@testable import Baymax

@MainActor
@Suite("UserDefaults tool store", .serialized)
struct UserDefaultsStoreTests {

    private let suiteName = "BaymaxTests.UserDefaultsStore"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeStore(protectedKeys: Set<String> = []) -> UserDefaultsStore {
        UserDefaultsStore(defaults: defaults, domainName: suiteName, protectedKeys: protectedKeys)
    }

    private func entry(_ key: String, in store: UserDefaultsStore) throws -> UserDefaultsEntry {
        try #require(store.entries.first { $0.key == key })
    }

    // MARK: - Listing

    @Test("App keys and system keys are listed separately")
    func systemKeysSeparated() {
        defaults.set("app", forKey: "appKey")
        let store = makeStore()

        #expect(store.entries.map(\.key) == ["appKey"])
        #expect(!store.systemEntries.isEmpty)
        #expect(!store.systemEntries.contains { $0.key == "appKey" })
        #expect(store.systemEntries.allSatisfy { $0.isSystem })
    }

    @Test("System keys are read-only and can't be deleted")
    func systemKeysReadOnly() throws {
        let store = makeStore()
        let systemEntry = try #require(store.systemEntries.first)

        #expect(!systemEntry.isEditable)
        #expect(!systemEntry.isDeletable)
        #expect(!store.update(systemEntry.key, to: "changed"))
        #expect(!store.delete(systemEntry.key))
        #expect(defaults.persistentDomain(forName: suiteName)?[systemEntry.key] == nil)
    }

    @Test("Entries are sorted by key")
    func sorted() {
        defaults.set(1, forKey: "b")
        defaults.set(1, forKey: "a")

        #expect(makeStore().entries.map(\.key) == ["a", "b"])
    }

    @Test("Classifies each type, telling Bool from Number")
    func classifiesTypes() throws {
        defaults.set("text", forKey: "string")
        defaults.set(3, forKey: "int")
        defaults.set(1.5, forKey: "double")
        defaults.set(true, forKey: "bool")
        defaults.set(Date(), forKey: "date")
        defaults.set(Data([1, 2]), forKey: "data")
        defaults.set([1, 2], forKey: "array")
        defaults.set(["a": 1], forKey: "dictionary")
        let store = makeStore()

        #expect(try entry("string", in: store).type == .string)
        #expect(try entry("int", in: store).type == .number)
        #expect(try entry("double", in: store).type == .number)
        #expect(try entry("bool", in: store).type == .bool)
        #expect(try entry("date", in: store).type == .date)
        #expect(try entry("data", in: store).type == .data)
        #expect(try entry("array", in: store).type == .array)
        #expect(try entry("dictionary", in: store).type == .dictionary)
        #expect(try entry("int", in: store).isInteger)
        #expect(try !entry("double", in: store).isInteger)
    }

    @Test("Data is read-only; arrays and dictionaries are editable containers")
    func editableTypes() throws {
        defaults.set(Data([1]), forKey: "data")
        defaults.set([1], forKey: "array")
        defaults.set(["a": 1], forKey: "dictionary")
        let store = makeStore()

        #expect(try !entry("data", in: store).isEditable)
        #expect(try entry("array", in: store).isEditable)
        #expect(try entry("dictionary", in: store).isEditable)
        #expect(try entry("array", in: store).type.isContainer)
        #expect(try entry("dictionary", in: store).type.isContainer)
    }

    @Test("Saving an edited container writes the whole value back")
    func containerSaveRoundTrip() throws {
        defaults.set(["keep": 1, "drop": 2], forKey: "dictionary")
        let store = makeStore()
        let original = try entry("dictionary", in: store).value

        let edited = PlistEditing.removing(at: [.key("drop")], in: original)
        #expect(store.update("dictionary", to: edited))

        let stored = try #require(defaults.dictionary(forKey: "dictionary"))
        #expect(stored.keys.sorted() == ["keep"])
    }

    // MARK: - Editing

    @Test("Edits round-trip for String, Bool and Date")
    func editsRoundTrip() {
        let date = Date(timeIntervalSince1970: 1_000)
        defaults.set("old", forKey: "string")
        defaults.set(false, forKey: "bool")
        defaults.set(Date(), forKey: "date")
        let store = makeStore()

        #expect(store.update("string", to: "new"))
        #expect(store.update("bool", to: true))
        #expect(store.update("date", to: date))

        #expect(defaults.string(forKey: "string") == "new")
        #expect(defaults.bool(forKey: "bool"))
        #expect(defaults.object(forKey: "date") as? Date == date)
        #expect(store.hasChanges)
    }

    @Test("Number edits keep the Int or Double type")
    func numberEditsKeepType() throws {
        defaults.set(3, forKey: "int")
        defaults.set(1.5, forKey: "double")
        let store = makeStore()

        #expect(store.updateNumber(try entry("int", in: store), from: "42"))
        #expect(store.updateNumber(try entry("double", in: store), from: "2.25"))

        #expect(try entry("int", in: store).isInteger)
        #expect(defaults.integer(forKey: "int") == 42)
        #expect(try !entry("double", in: store).isInteger)
        #expect(defaults.double(forKey: "double") == 2.25)
    }

    @Test("Invalid number text is refused")
    func invalidNumberRefused() throws {
        defaults.set(3, forKey: "int")
        let store = makeStore()

        #expect(!store.updateNumber(try entry("int", in: store), from: "1.5"))
        #expect(!store.updateNumber(try entry("int", in: store), from: "abc"))
        #expect(defaults.integer(forKey: "int") == 3)
        #expect(!store.hasChanges)
    }

    @Test("Delete removes the key")
    func deleteRemovesKey() {
        defaults.set("value", forKey: "key")
        let store = makeStore()

        #expect(store.delete("key"))

        #expect(defaults.object(forKey: "key") == nil)
        #expect(store.entries.isEmpty)
    }

    // MARK: - Protected keys

    @Test("Protected keys refuse edit and delete")
    func protectedKeys() throws {
        defaults.set("secret", forKey: "protected")
        let store = makeStore(protectedKeys: ["protected"])

        #expect(try entry("protected", in: store).isProtected)
        #expect(try !entry("protected", in: store).isEditable)
        #expect(!store.update("protected", to: "changed"))
        #expect(!store.delete("protected"))
        #expect(defaults.string(forKey: "protected") == "secret")
        #expect(!store.hasChanges)
    }

    // MARK: - Built-in registration

    @Test("Listed first in the General section")
    func registeredInGeneral() {
        #expect(BaymaxServices().diagnosticTools.first is UserDefaultsTool)
    }
}
