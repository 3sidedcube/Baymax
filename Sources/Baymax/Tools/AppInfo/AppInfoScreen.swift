//
//  AppInfoScreen.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// App, device and recorded values. Tap a row to copy it; the share button shares everything as text.
struct AppInfoScreen: View {

    @State private var sections = AppInfoTool.sections()
    @State private var isLoadingProvided = false
    @State private var copiedMessage: String?

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                Section {
                    ForEach(section.rows, id: \.self) { row in
                        Button { copy(row.value, message: "Copied \(row.title)") } label: {
                            // Small secondary title above the value, so long tokens get the full width.
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.footnote)
                                    .foregroundStyle(Color.black)
                                Text(row.value)
                                    .font(.body.monospaced())
                                    .foregroundStyle(Color.black)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                        .accessibilityHint("Copies the value")
                    }
                    if section.title == AppInfoTool.fromAppTitle, isLoadingProvided {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading…")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(section.title)
                } footer: {
                    if section.rows.isEmpty, !isLoadingProvided {
                        Text("Nothing from the app. It adds values with AppInfoTool.record(_:) or AppInfoTool.provide(_:).")
                    }
                }
            }
        }
        .toolbar {
            // The system share sheet (UIActivityViewController), which also offers Copy.
            ShareLink(item: AppInfoTool.copyAllText(of: sections)) {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel("Share all info")
            }
        }
        .overlay(alignment: .bottom) {
            if let copiedMessage {
                Text(copiedMessage)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityHidden(true)
            }
        }
        .animation(.default, value: copiedMessage)
        // Each time the screen appears: show recorded values straight away, then run the providers.
        // This also keeps App Check expiry relative to now.
        .task { await refresh() }
    }

    private func refresh() async {
        sections = AppInfoTool.sections()
        guard !AppInfoTool.providers.isEmpty else { return }

        isLoadingProvided = true
        let provided = await AppInfoTool.provided()
        sections = AppInfoTool.sections(fromApp: AppInfoTool.merging(AppInfoTool.recorded, with: provided))
        isLoadingProvided = false
    }

    private func copy(_ text: String, message: String) {
        UIPasteboard.general.string = text
        copiedMessage = message
        AccessibilityNotification.Announcement(message).post()

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedMessage == message { copiedMessage = nil }
        }
    }
}
