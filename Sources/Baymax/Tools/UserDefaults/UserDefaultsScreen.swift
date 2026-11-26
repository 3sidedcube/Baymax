//
//  UserDefaultsScreen.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Lists UserDefaults keys with search, inline Bool toggles, swipe to delete, and an editor sheet.
struct UserDefaultsScreen: View {

    @StateObject private var store: UserDefaultsStore
    @State private var searchText = ""
    @State private var editingEntry: UserDefaultsEntry?
    @State private var pendingDeletion: UserDefaultsEntry?
    /// System keys are folded away by default.
    @State private var showsSystemKeys = false

    init(store: UserDefaultsStore) {
        _store = StateObject(wrappedValue: store)
    }

    private func filtered(_ entries: [UserDefaultsEntry]) -> [UserDefaultsEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        let appEntries = filtered(store.entries)
        let systemEntries = filtered(store.systemEntries)

        List {
            Section {
                ForEach(appEntries) { entry in
                    row(for: entry)
                        .swipeActions {
                            if entry.isDeletable {
                                Button("Delete", role: .destructive) { pendingDeletion = entry }
                            }
                        }
                }
            }

            if !systemEntries.isEmpty {
                Section {
                    // Unfolds while searching, so matching system keys aren't hidden.
                    DisclosureGroup(
                        "System keys (\(systemEntries.count))",
                        isExpanded: Binding(
                            get: { showsSystemKeys || !searchText.isEmpty },
                            set: { showsSystemKeys = $0 }
                        )
                    ) {
                        ForEach(systemEntries) { entry in
                            row(for: entry)
                        }
                    }
                } footer: {
                    Text("Apple's global keys. Read-only.")
                }
            }

            if store.hasChanges {
                Section {
                    Label("Some apps read values only at launch, so a relaunch may be needed.", systemImage: "arrow.clockwise")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if appEntries.isEmpty && systemEntries.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView("No keys", systemImage: "tray")
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search keys")
        .sheet(item: $editingEntry) { entry in
            if entry.type.isContainer {
                UserDefaultsContainerEditor(entry: entry, store: store)
            } else {
                UserDefaultsEditor(entry: entry, store: store)
            }
        }
        .confirmationDialog(
            "Delete \(pendingDeletion?.key ?? "")?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let key = pendingDeletion?.key { store.delete(key) }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: UserDefaultsEntry) -> some View {
        if entry.type == .bool, entry.isEditable {
            Toggle(isOn: Binding(
                get: { entry.value as? Bool ?? false },
                set: { store.update(entry.key, to: $0) }
            )) {
                UserDefaultsRowLabel(entry: entry, showsPreview: false)
            }
        } else {
            Button { editingEntry = entry } label: {
                UserDefaultsRowLabel(entry: entry, showsPreview: true)
            }
            .foregroundStyle(.primary)
        }
    }
}

/// Key, type badge, lock for protected keys, and an optional value preview.
struct UserDefaultsRowLabel: View {

    let entry: UserDefaultsEntry
    let showsPreview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if entry.isProtected {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Protected")
                }
                Text(entry.key)
                    .font(.body.monospaced())
                    .lineLimit(2)
                Text(entry.type.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tint.opacity(0.15), in: Capsule())
            }
            if showsPreview {
                Text(entry.preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Edits a String, Number or Date; shows other types (and protected keys) read-only.
private struct UserDefaultsEditor: View {

    let entry: UserDefaultsEntry
    let store: UserDefaultsStore

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var date: Date

    init(entry: UserDefaultsEntry, store: UserDefaultsStore) {
        self.entry = entry
        self.store = store
        _text = State(initialValue: entry.type == .date ? "" : String(describing: entry.value))
        _date = State(initialValue: entry.value as? Date ?? Date())
    }

    private var isValid: Bool {
        entry.type != .number || PlistEditing.parseNumber(text, integer: entry.isInteger) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    editor
                } header: {
                    Text(entry.type.rawValue)
                } footer: {
                    if entry.isProtected {
                        Text("Protected: this key can't be edited or deleted from Baymax.")
                    } else if entry.isSystem {
                        Text("Apple's global key: read-only.")
                    } else if !entry.type.isEditable {
                        Text("\(entry.type.rawValue) values are read-only.")
                    } else if !isValid {
                        Text(entry.isInteger ? "Enter a whole number." : "Enter a number.")
                    }
                }
            }
            .navigationTitle(entry.key)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(entry.isEditable ? "Cancel" : "Done") { dismiss() }
                }
                if entry.isEditable {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .disabled(!isValid)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var editor: some View {
        if entry.isEditable {
            ScalarValueField(type: entry.type, text: $text, date: $date)
        } else {
            Text(entry.fullDescription)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
        }
    }

    private func save() {
        switch entry.type {
        case .string: store.update(entry.key, to: text)
        case .number: store.updateNumber(entry, from: text)
        case .date: store.update(entry.key, to: date)
        default: break
        }
        dismiss()
    }
}

/// The input for a String, Number or Date value, shared by the key editor and the item editor.
struct ScalarValueField: View {

    let type: UserDefaultsValueType
    @Binding var text: String
    @Binding var date: Date

    var body: some View {
        switch type {
        case .string:
            TextField("Value", text: $text, axis: .vertical)
        case .number:
            TextField("Value", text: $text)
                .keyboardType(.numbersAndPunctuation)
        case .date:
            DatePicker("Value", selection: $date)
        default:
            EmptyView()
        }
    }
}
