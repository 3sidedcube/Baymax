//
//  PlistEditing.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// One step into an array (by index) or a dictionary (by key).
enum PlistPathComponent: Hashable {
    case index(Int)
    case key(String)

    /// Shown as the item's name: `0`, `1`, … for arrays, the key for dictionaries.
    var label: String {
        switch self {
        case .index(let index): return String(index)
        case .key(let key): return key
        }
    }
}

/// Reads, replaces and removes values at any depth inside UserDefaults arrays and dictionaries.
/// Pure functions returning a new root, so an editor can work on a copy until it saves.
enum PlistEditing {

    /// The items of an array (in order) or dictionary (sorted by key); empty for anything else.
    static func children(of container: Any) -> [(component: PlistPathComponent, value: Any)] {
        if let array = container as? [Any] {
            return array.enumerated().map { (.index($0.offset), $0.element) }
        }
        if let dictionary = container as? [String: Any] {
            return dictionary.keys.sorted().map { (.key($0), dictionary[$0] as Any) }
        }
        return []
    }

    static func value(at path: [PlistPathComponent], in root: Any) -> Any? {
        guard let first = path.first else { return root }
        guard let child = child(first, of: root) else { return nil }
        return value(at: Array(path.dropFirst()), in: child)
    }

    /// `root` with the value at `path` replaced by `newValue`. Unchanged if the path doesn't exist.
    static func setting(_ newValue: Any, at path: [PlistPathComponent], in root: Any) -> Any {
        guard let first = path.first else { return newValue }
        guard let child = child(first, of: root) else { return root }
        let updatedChild = setting(newValue, at: Array(path.dropFirst()), in: child)
        return replacing(first, with: updatedChild, in: root)
    }

    /// `root` with the value at `path` removed. Unchanged if the path doesn't exist.
    static func removing(at path: [PlistPathComponent], in root: Any) -> Any {
        guard let first = path.first else { return root }

        if path.count == 1 {
            switch (first, root) {
            case (.index(let index), var array as [Any]) where array.indices.contains(index):
                array.remove(at: index)
                return array
            case (.key(let key), var dictionary as [String: Any]):
                dictionary.removeValue(forKey: key)
                return dictionary
            default:
                return root
            }
        }

        guard let child = child(first, of: root) else { return root }
        return replacing(first, with: removing(at: Array(path.dropFirst()), in: child), in: root)
    }

    /// Parses `text` as an Int (if `integer`) or Double. `nil` if it isn't a valid number.
    static func parseNumber(_ text: String, integer: Bool) -> Any? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return integer ? Int(trimmed) : Double(trimmed)
    }

    /// Whether two values differ, comparing nested arrays and dictionaries deeply.
    static func differs(_ lhs: Any, _ rhs: Any) -> Bool {
        !(lhs as AnyObject).isEqual(rhs as AnyObject)
    }

    private static func child(_ component: PlistPathComponent, of container: Any) -> Any? {
        switch (component, container) {
        case (.index(let index), let array as [Any]):
            return array.indices.contains(index) ? array[index] : nil
        case (.key(let key), let dictionary as [String: Any]):
            return dictionary[key]
        default:
            return nil
        }
    }

    private static func replacing(_ component: PlistPathComponent, with value: Any, in container: Any) -> Any {
        switch (component, container) {
        case (.index(let index), var array as [Any]) where array.indices.contains(index):
            array[index] = value
            return array
        case (.key(let key), var dictionary as [String: Any]):
            dictionary[key] = value
            return dictionary
        default:
            return container
        }
    }
}
