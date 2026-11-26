//
//  BaymaxRow.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// A "Diagnostics" row for a `List` or `Form` that opens Baymax.
/// Takes up no row while Baymax isn't attached (e.g. in production builds), or until the Simulator is shaken.
///
/// - Important: Only shown on the Simulator (e.g. DeviceHub, which can't perform the multi-finger swipe).
///   Always hidden on real devices, so it never appears in release builds; there, Baymax is opened with the multi-finger swipe gesture.
public struct BaymaxRow: View {

    private let manager: DiagnosticsManager

    public init() {
        self.init(manager: .shared)
    }

    init(manager: DiagnosticsManager) {
        self.manager = manager
    }

    public var body: some View {
        BaymaxEntry(manager: manager) { open in
            Button(action: open) {
                // Full width and leading outside a List too (e.g. in a VStack), with the whole row tappable.
                Label {
                    Text(verbatim: BaymaxEntryText.title)
                        .font(.headline)
                } icon: {
                    Text(verbatim: BaymaxEntryText.ascii)
                        .foregroundStyle(Color.white)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .background {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white)
                }
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.16), radius: 4)
            }
            .accessibilityLabel(BaymaxEntryText.accessibilityLabel)
        }
    }
}
