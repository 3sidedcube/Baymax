//
//  UserDefaultsContainerEditor.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Sheet for an array or dictionary key: edit or delete its items at any depth.
/// Works on a copy; only Save writes back to UserDefaults, and Cancel discards everything.
struct UserDefaultsContainerEditor: View {

    let entry: UserDefaultsEntry
    let store: UserDefaultsStore

    @Environment(\.dismiss) private var dismiss
    @State private var working: Any

    init(entry: UserDefaultsEntry, store: UserDefaultsStore) {
        self.entry = entry
        self.store = store
        _working = State(initialValue: entry.value)
    }

    var body: some View {
        NavigationStack {
            PlistContainerView(path: [], root: $working, isEditable: entry.isEditable)
                .navigationTitle(entry.key)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(entry.isEditable ? "Cancel" : "Done") { dismiss() }
                    }
                    if entry.isEditable {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                store.update(entry.key, to: working)
                                dismiss()
                            }
                            .disabled(!PlistEditing.differs(working, entry.value))
                        }
                    }
                }
        }
    }
}

/// The items of the array or dictionary at `path` inside `root`.
private struct PlistContainerView: View {

    let path: [PlistPathComponent]
    @Binding var root: Any
    let isEditable: Bool

    private var children: [(component: PlistPathComponent, value: Any)] {
        PlistEditing.value(at: path, in: root).map(PlistEditing.children) ?? []
    }

    var body: some View {
        List {
            ForEach(children, id: \.component) { child in
                row(for: child.component, value: child.value)
                    .swipeActions {
                        if isEditable {
                            Button("Delete", role: .destructive) {
                                root = PlistEditing.removing(at: path + [child.component], in: root)
                            }
                        }
                    }
            }
        }
        .overlay {
            if children.isEmpty {
                ContentUnavailableView("No items", systemImage: "tray")
            }
        }
    }

    @ViewBuilder
    private func row(for component: PlistPathComponent, value: Any) -> some View {
        let itemPath = path + [component]
        let item = UserDefaultsEntry(
            key: component.label,
            value: value,
            type: UserDefaultsValueType(of: value),
            isProtected: false,
            isSystem: !isEditable
        )

        if item.type == .bool, isEditable {
            Toggle(isOn: Binding(
                get: { value as? Bool ?? false },
                set: { root = PlistEditing.setting($0, at: itemPath, in: root) }
            )) {
                UserDefaultsRowLabel(entry: item, showsPreview: false)
            }
        } else if item.type.isContainer {
            NavigationLink {
                PlistContainerView(path: itemPath, root: $root, isEditable: isEditable)
                    .navigationTitle(component.label)
            } label: {
                UserDefaultsRowLabel(entry: item, showsPreview: true)
            }
        } else {
            NavigationLink {
                PlistItemEditor(path: itemPath, root: $root, item: item)
            } label: {
                UserDefaultsRowLabel(entry: item, showsPreview: true)
            }
        }
    }
}

/// Edits one String, Number or Date item; shows other items read-only.
/// Done applies the change to the sheet's copy; Back discards it.
private struct PlistItemEditor: View {

    let path: [PlistPathComponent]
    @Binding var root: Any
    let item: UserDefaultsEntry

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var date: Date

    init(path: [PlistPathComponent], root: Binding<Any>, item: UserDefaultsEntry) {
        self.path = path
        _root = root
        self.item = item
        _text = State(initialValue: item.type == .date ? "" : String(describing: item.value))
        _date = State(initialValue: item.value as? Date ?? Date())
    }

    private var isValid: Bool {
        item.type != .number || PlistEditing.parseNumber(text, integer: item.isInteger) != nil
    }

    var body: some View {
        Form {
            Section {
                if item.isEditable {
                    ScalarValueField(type: item.type, text: $text, date: $date)
                } else {
                    Text(item.fullDescription)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
            } header: {
                Text(item.type.rawValue)
            } footer: {
                if !item.type.isEditable {
                    Text("\(item.type.rawValue) values are read-only.")
                } else if !isValid {
                    Text(item.isInteger ? "Enter a whole number." : "Enter a number.")
                }
            }
        }
        .navigationTitle(item.key)
        .toolbar {
            if item.isEditable {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { apply() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func apply() {
        let newValue: Any?
        switch item.type {
        case .string: newValue = text
        case .number: newValue = PlistEditing.parseNumber(text, integer: item.isInteger)
        case .date: newValue = date
        default: newValue = nil
        }
        if let newValue {
            root = PlistEditing.setting(newValue, at: path, in: root)
        }
        dismiss()
    }
}
