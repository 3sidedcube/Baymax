//
//  BaymaxEntry.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Combine
import SwiftUI

/// Shows its content only while Baymax is attached and the controls are switched on, and hands it an `open` action.
/// The controls start hidden; shake the Simulator (Device › Shake, ⌃⌘Z) to show or hide them.
///
/// Use it to open Baymax from a control styled like the rest of your app:
/// ```swift
/// BaymaxEntry { open in
///     MyListItem(title: "Diagnostics", onTap: open)
/// }
/// ```
/// `open` runs the authentication handler given to `attach(to:)`, if any, before showing Baymax.
///
/// - Important: Only shown on the Simulator (e.g. DeviceHub, which can't perform the multi-finger swipe).
///   Always hidden on real devices, so it never appears in release builds; there, Baymax is opened with the multi-finger swipe gesture.
public struct BaymaxEntry<Content: View>: View {

    @StateObject private var attachment: AttachmentState
    private let content: (_ open: @escaping () -> Void) -> Content

    public init(@ViewBuilder content: @escaping (_ open: @escaping () -> Void) -> Content) {
        self.init(manager: .shared, content: content)
    }

    init(manager: DiagnosticsManager, @ViewBuilder content: @escaping (_ open: @escaping () -> Void) -> Content) {
        _attachment = StateObject(wrappedValue: AttachmentState(manager: manager))
        self.content = content
    }

    public var body: some View {
        // Simulator only: on real devices (every release build), Baymax is opened with the swipe gesture.
        #if targetEnvironment(simulator)
        if attachment.isShown {
            content(attachment.open)
        }
        #endif
    }
}

/// Mirrors `DiagnosticsManager.isAttached` and the shake switch, updating when either changes.
final class AttachmentState: ObservableObject {

    @Published private(set) var isAttached: Bool
    @Published private(set) var isVisible: Bool

    /// Whether the entry's content is shown
    var isShown: Bool { isAttached && isVisible }

    private let manager: DiagnosticsManager
    private var cancellables = Set<AnyCancellable>()

    init(manager: DiagnosticsManager) {
        self.manager = manager
        isAttached = manager.isAttached
        isVisible = manager.entryVisibility.isVisible
        NotificationCenter.default
            .publisher(for: DiagnosticsManager.attachmentDidChangeNotification, object: manager)
            .sink { [weak self] _ in
                self?.isAttached = manager.isAttached
            }
            .store(in: &cancellables)
        manager.entryVisibility.$isVisible
            .dropFirst()
            .sink { [weak self] in
                self?.isVisible = $0
            }
            .store(in: &cancellables)
    }

    func open() {
        manager.requestPresentation()
    }
}
