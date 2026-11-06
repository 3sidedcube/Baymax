//
//  BaymaxFloatingButton.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

extension View {

    /// Adds a small draggable button over this view that opens Baymax.
    /// Apply it to one screen's root view; the button exists only on that screen,
    /// and is hidden while Baymax isn't attached (e.g. in production builds), or until the Simulator is shaken.
    ///
    /// - Important: Only shown on the Simulator (e.g. DeviceHub, which can't perform the multi-finger swipe).
    ///   Always hidden on real devices, so it never appears in release builds; there, Baymax is opened with the multi-finger swipe gesture.
    public func baymaxButton() -> some View {
        overlay {
#if targetEnvironment(simulator)
            BaymaxFloatingButton(manager: .shared)
#endif
        }
    }
}

/// The overlay behind `baymaxButton()`. Fills the screen but only the button itself takes touches.
/// Simulator use only, like every entry control; see `baymaxButton()`.
struct BaymaxFloatingButton: View {

    let manager: DiagnosticsManager

    /// Centre of the button; `nil` until first dragged, meaning the bottom-trailing corner.
    @State private var position: CGPoint?

    /// The circle's size, measured from the content, so dragging keeps the whole circle on screen.
    @State private var diameter: CGFloat = 44
    private let margin: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            BaymaxEntry(manager: manager) { open in
                Button(action: open) {
                    Text(verbatim: BaymaxEntryText.ascii)
                        .padding(6)
                        .background {
                            Circle()
                                .fill(Color.white)
                                .scaledToFill()
                                .modifier(FloatingButtonBackground())
                        }
                        .onGeometryChange(for: CGFloat.self) {
                            max($0.size.width, $0.size.height)
                        } action: {
                            diameter = $0
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BaymaxEntryText.accessibilityLabel)
                .position(position ?? defaultPosition(in: geometry.size))
                // Needs real movement, so a tap still reaches the button.
                .highPriorityGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { position = clamped($0.location, in: geometry.size) }
                )
            }
        }
    }

    private func defaultPosition(in size: CGSize) -> CGPoint {
        clamped(CGPoint(x: size.width, y: size.height), in: size)
    }

    /// Keeps the whole button inside the container (which respects the safe area) with a margin.
    func clamped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let inset = margin + diameter / 2
        return CGPoint(
            x: min(max(point.x, inset), max(inset, size.width - inset)),
            y: min(max(point.y, inset), max(inset, size.height - inset))
        )
    }
}

/// Liquid Glass on iOS 26+, a material circle before that.
private struct FloatingButtonBackground: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content.background(.regularMaterial, in: Circle())
        }
    }
}
