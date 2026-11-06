//
//  UserDefaultsStore.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// The kinds of value UserDefaults can hold, as shown and edited by the UserDefaults tool.
enum UserDefaultsValueType: String {
    case string = "String"
    case number = "Number"
    case bool = "Bool"
    case date = "Date"
    case data = "Data"
    case array = "Array"
    case dictionary = "Dictionary"
    case other = "Other"

    /// Whether the tool can edit this type. Arrays and dictionaries are edited item by item; data is read-only.
    var isEditable: Bool {
        switch self {
        case .string, .number, .bool, .date, .array, .dictionary: return true
        case .data, .other: return false
        }
    }

    /// Arrays and dictionaries, which open as a list of their items.
    var isContainer: Bool {
        self == .array || self == .dictionary
    }

    init(of value: Any) {
        switch value {
        case is String: self = .string
        case is Date: self = .date
        case is Data: self = .data
        // Bools and numbers both arrive as NSNumber; CFBoolean tells them apart.
        case let number as NSNumber:
            self = CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool : .number
        case is [Any]: self = .array
        case is [String: Any]: self = .dictionary
        default: self = .other
        }
    }
}

/// One stored key and its value.
struct UserDefaultsEntry: Identifiable {
    let key: String
    let value: Any
    let type: UserDefaultsValueType
    let isProtected: Bool
    /// Apple's global keys (`Apple*`, `NS*`, …), not the app's own. Shown read-only.
    var isSystem = false

    var id: String { key }

    /// Whether it can be deleted: the app's own, unprotected keys only.
    var isDeletable: Bool { !isProtected && !isSystem }

    /// Editable only if the type supports it and the key can be changed.
    var isEditable: Bool { type.isEditable && isDeletable }

    /// Whether a number is an integer, so edits keep it an Int rather than a Double.
    var isInteger: Bool {
        guard let number = value as? NSNumber else { return false }
        return !CFNumberIsFloatType(number)
    }

    /// One-line summary for the list.
    var preview: String {
        switch type {
        case .bool: return (value as? Bool ?? false) ? "true" : "false"
        case .date: return (value as? Date)?.formatted(date: .abbreviated, time: .standard) ?? ""
        case .data: return "\((value as? Data)?.count ?? 0) bytes"
        case .array: return "\((value as? [Any])?.count ?? 0) items"
        case .dictionary: return "\((value as? [String: Any])?.count ?? 0) keys"
        case .string, .number, .other: return String(describing: value)
        }
    }

    /// Full value for the read-only detail view.
    var fullDescription: String {
        guard let data = value as? Data else { return String(describing: value) }
        let hex = data.prefix(64).map { String(format: "%02x", $0) }.joined(separator: " ")
        return "\(data.count) bytes\n\(hex)\(data.count > 64 ? " …" : "")"
    }
}

/// Reads, edits and deletes UserDefaults values for the UserDefaults tool.
@MainActor
final class UserDefaultsStore: ObservableObject {

    /// The app's own keys.
    @Published private(set) var entries: [UserDefaultsEntry] = []

    /// Apple's global keys (`Apple*`, `NS*`, …), read-only.
    @Published private(set) var systemEntries: [UserDefaultsEntry] = []

    /// Set after any edit or delete, so the screen can suggest a relaunch.
    @Published private(set) var hasChanges = false

    private let defaults: UserDefaults
    private let domainName: String?
    private let protectedKeys: Set<String>
    private var systemKeys: Set<String> = []

    /// - Parameters:
    ///   - defaults: The defaults to show; `.standard` in the app.
    ///   - domainName: The app's own domain, holding only the app's keys; the bundle ID in the app.
    ///   - protectedKeys: Keys shown read-only and never deleted.
    init(
        defaults: UserDefaults = .standard,
        domainName: String? = Bundle.main.bundleIdentifier,
        protectedKeys: Set<String> = []
    ) {
        self.defaults = defaults
        self.domainName = domainName
        self.protectedKeys = protectedKeys
        reload()
    }

    func reload() {
        let appValues = domainName.flatMap { defaults.persistentDomain(forName: $0) } ?? [:]
        let systemValues = defaults.dictionaryRepresentation().filter { appValues[$0.key] == nil }

        systemKeys = Set(systemValues.keys)
        entries = makeEntries(appValues, isSystem: false)
        systemEntries = makeEntries(systemValues, isSystem: true)
    }

    private func makeEntries(_ values: [String: Any], isSystem: Bool) -> [UserDefaultsEntry] {
        values.keys.sorted().map { key in
            UserDefaultsEntry(
                key: key,
                value: values[key] as Any,
                type: UserDefaultsValueType(of: values[key] as Any),
                isProtected: protectedKeys.contains(key),
                isSystem: isSystem
            )
        }
    }

    /// Whether `key` may be changed: not protected, and not one of Apple's global keys.
    private func canChange(_ key: String) -> Bool {
        !protectedKeys.contains(key) && !systemKeys.contains(key)
    }

    /// Stores `value` for `key`. Refuses protected and system keys.
    @discardableResult
    func update(_ key: String, to value: Any) -> Bool {
        guard canChange(key) else { return false }
        defaults.set(value, forKey: key)
        hasChanges = true
        reload()
        return true
    }

    /// Parses `text` as the entry's number type (Int or Double) and stores it.
    /// Returns `false` if the text isn't a valid number or the key is protected.
    @discardableResult
    func updateNumber(_ entry: UserDefaultsEntry, from text: String) -> Bool {
        guard let number = PlistEditing.parseNumber(text, integer: entry.isInteger) else { return false }
        return update(entry.key, to: number)
    }

    /// Removes `key`. Refuses protected and system keys.
    @discardableResult
    func delete(_ key: String) -> Bool {
        guard canChange(key) else { return false }
        defaults.removeObject(forKey: key)
        hasChanges = true
        reload()
        return true
    }
}
