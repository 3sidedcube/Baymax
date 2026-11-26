//
//  BaymaxEmptyState.swift
//  Baymax
//
//  Created by Szuyun Liang on 23/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Shown in the diagnostics menu when no provider is visible.
struct BaymaxEmptyState: View {

    static let title = "Nothing to see here"
    static let message = "Diagnostics aren't available in this build."

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(verbatim: Self.title)
            } icon: {
                BaymaxFace()
            }
        } description: {
            Text(verbatim: Self.message)
        }
    }
}

// MARK: - Face

/// Baymax's face: two dots joined by a line. Drawn rather than an image, so it follows light and dark mode.
struct BaymaxFace: View {

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .frame(width: 20, height: 20)
            Rectangle()
                .frame(width: 56, height: 3)
            Circle()
                .frame(width: 20, height: 20)
        }
        .foregroundStyle(.primary)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    BaymaxEmptyState()
}
