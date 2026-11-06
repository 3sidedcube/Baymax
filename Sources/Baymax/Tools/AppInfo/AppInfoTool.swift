//
//  AppInfoTool.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import SwiftUI

/// Shows app and device details, plus values the app records, all copyable. Built in, in the "General" section.
public struct AppInfoTool: SwiftUIDiagnosticTool {

    /// Values recorded by the app, in the order first recorded.
    static var recorded: [AppInfo] = []

    /// Closures given to `provide(_:)`, run each time the tool opens.
    static var providers: [() async -> [AppInfo]] = []

    /// Records a value to show, replacing an earlier one with the same identity
    /// (same token type, or same `custom` title). Use it for values the app is handed
    /// through a callback, whenever they change, e.g.:
    /// ```swift
    /// AppInfoTool.record(.apnsToken(deviceToken: deviceToken))
    /// AppInfoTool.record(.custom(title: "Environment", value: "dev"))
    /// ```
    public static func record(_ info: AppInfo) {
        recorded = merging(recorded, with: [info])
    }

    /// Supplies values that Baymax fetches only when the tool opens, so nothing runs at launch
    /// or while Baymax is closed. Provided values replace recorded ones with the same identity. E.g.:
    /// ```swift
    /// AppInfoTool.provide {
    ///     guard let token = try? await AppCheck.appCheck().token(forcingRefresh: false) else { return [] }
    ///     return [.appCheckToken(token.token)]
    /// }
    /// ```
    public static func provide(_ provider: @escaping () async -> [AppInfo]) {
        providers.append(provider)
    }

    /// Runs every provider, in the order given.
    static func provided() async -> [AppInfo] {
        var values: [AppInfo] = []
        for provider in providers {
            values = merging(values, with: await provider())
        }
        return values
    }

    /// `base` with each of `newer` replacing the value with the same identity in place, or appended.
    static func merging(_ base: [AppInfo], with newer: [AppInfo]) -> [AppInfo] {
        var merged = base
        for info in newer {
            if let index = merged.firstIndex(where: { $0.identity == info.identity }) {
                merged[index] = info
            } else {
                merged.append(info)
            }
        }
        return merged
    }

    public init() {}

    public var displayName: String {
        return "App & device info"
    }

    public func makeView() -> some View {
        AppInfoScreen()
    }

    /// Title of the section holding recorded and provided values.
    static let fromAppTitle = "From the app"

    /// All sections shown on screen, built fresh so expiry times are relative to `now`.
    /// - Parameter fromApp: Recorded values merged with provided ones.
    static func sections(
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:],
        fromApp: [AppInfo] = recorded,
        now: Date = Date()
    ) -> [AppInfoSection] {
        let string = { (key: String) in infoDictionary[key] as? String ?? "Unknown" }

        let app = AppInfoSection(title: "App", rows: [
            AppInfoRow(title: "Name", value: infoDictionary["CFBundleDisplayName"] as? String ?? string("CFBundleName")),
            AppInfoRow(title: "Version", value: string("CFBundleShortVersionString")),
            AppInfoRow(title: "Build", value: string("CFBundleVersion")),
            AppInfoRow(title: "Bundle ID", value: string("CFBundleIdentifier"))
        ])

        let device = AppInfoSection(title: "Device", rows: [
            AppInfoRow(title: "Model", value: modelIdentifier),
            AppInfoRow(title: "iOS", value: UIDevice.current.systemVersion),
            AppInfoRow(title: "Locale", value: Locale.current.identifier),
            AppInfoRow(title: "Time zone", value: TimeZone.current.identifier)
        ])

        let fromAppSection = AppInfoSection(title: fromAppTitle, rows: fromApp.map { $0.row(now: now) })

        return [fromAppSection, app, device]
    }

    /// Plain text of every row, for pasting into tickets or Slack.
    static func copyAllText(of sections: [AppInfoSection]) -> String {
        sections
            .filter { !$0.rows.isEmpty }
            .map { section in
                ([section.title] + section.rows.map { "\($0.title): \($0.value)" }).joined(separator: "\n")
            }
            .joined(separator: "\n\n")
    }

    /// e.g. `iPhone17,1`. On the Simulator, the simulated device's identifier rather than the Mac's.
    private static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: systemInfo.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
