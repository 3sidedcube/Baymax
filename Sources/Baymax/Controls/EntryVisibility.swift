//
//  EntryVisibility.swift
//  Baymax
//
//  Created by Szuyun Liang on 06/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Combine
import UIKit

/// Whether the entry controls are switched on. Hidden by default, so screenshots, UI tests and demos
/// on the Simulator don't show them; a shake switches them on or off. Remembered across launches.
final class EntryVisibility: ObservableObject {

    static let defaultsKey = "BaymaxEntryControlsVisible"

    @Published private(set) var isVisible: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isVisible = defaults.bool(forKey: Self.defaultsKey)
    }

    func toggle() {
        isVisible.toggle()
        defaults.set(isVisible, forKey: Self.defaultsKey)
        UIAccessibility.post(
            notification: .announcement,
            argument: isVisible ? BaymaxEntryText.shownAnnouncement : BaymaxEntryText.hiddenAnnouncement
        )
    }
}
