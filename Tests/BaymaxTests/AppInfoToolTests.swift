//
//  AppInfoToolTests.swift
//  BaymaxTests
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation
import Testing
@testable import Baymax

@MainActor
@Suite("App & device info tool", .serialized)
struct AppInfoToolTests {

    init() {
        AppInfoTool.recorded = []
        AppInfoTool.providers = []
    }

    /// An unsigned JWT whose payload has `exp` set to `expiry`.
    private func jwt(expiry: Date) -> String {
        let payload = try! JSONSerialization.data(withJSONObject: ["exp": expiry.timeIntervalSince1970])
        let base64URL = payload.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "header.\(base64URL).signature"
    }

    // MARK: - AppInfo

    @Test("APNs device token converts to hex")
    func apnsHex() {
        let row = AppInfo.apnsToken(deviceToken: Data([0xAB, 0x01, 0xFF])).row()

        #expect(row == AppInfoRow(title: "APNs token", value: "ab01ff"))
    }

    @Test("FCM token is shown as is")
    func fcmToken() {
        #expect(AppInfo.fcmToken("abc:APA91b").row() == AppInfoRow(title: "FCM token", value: "abc:APA91b"))
    }

    @Test("App Check token shows its expiry, never the token")
    func appCheckShowsExpiryOnly() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let token = jwt(expiry: now.addingTimeInterval(3_600))

        let row = AppInfo.appCheckToken(token).row(now: now)

        #expect(row.title == "App Check expiry")
        #expect(!row.value.contains(token))
        #expect(!row.value.hasPrefix("Expired"))
        #expect(AppInfo.expiry(ofJWT: token) == now.addingTimeInterval(3_600))
    }

    @Test("An expired App Check token says so")
    func appCheckExpired() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        let value = AppInfo.appCheckToken(jwt(expiry: now.addingTimeInterval(-60))).row(now: now).value

        #expect(value.hasPrefix("Expired"))
    }

    @Test("A malformed App Check token is reported as unreadable")
    func appCheckUnreadable() {
        #expect(AppInfo.appCheckToken("not-a-jwt").row().value == "Unreadable token")
        #expect(AppInfo.expiry(ofJWT: "a.!!!.c") == nil)
    }

    // MARK: - Recording

    @Test("Recording replaces the same token type and custom title, keeping order")
    func recordReplaces() {
        AppInfoTool.record(.apnsToken("old"))
        AppInfoTool.record(.custom(title: "Environment", value: "dev"))
        AppInfoTool.record(.fcmToken("fcm-old"))
        AppInfoTool.record(.apnsToken("new"))
        AppInfoTool.record(.custom(title: "Environment", value: "staging"))
        AppInfoTool.record(.fcmToken("fcm-new"))
        AppInfoTool.record(.custom(title: "User", value: "42"))

        let rows = AppInfoTool.recorded.map { $0.row() }
        #expect(rows == [
            AppInfoRow(title: "APNs token", value: "new"),
            AppInfoRow(title: "Environment", value: "staging"),
            AppInfoRow(title: "FCM token", value: "fcm-new"),
            AppInfoRow(title: "User", value: "42")
        ])
    }

    // MARK: - Providing

    @Test("Providers run in order and replace values with the same identity")
    func providersMerge() async {
        AppInfoTool.provide { [.custom(title: "Environment", value: "dev"), .apnsToken("from-1")] }
        AppInfoTool.provide { [.apnsToken("from-2")] }

        let provided = await AppInfoTool.provided()

        #expect(provided.map { $0.row() } == [
            AppInfoRow(title: "Environment", value: "dev"),
            AppInfoRow(title: "APNs token", value: "from-2")
        ])
    }

    @Test("Provided values replace recorded ones in place; the rest stay")
    func providedReplacesRecorded() {
        let recorded: [AppInfo] = [.apnsToken("recorded"), .custom(title: "User", value: "42")]
        let provided: [AppInfo] = [.apnsToken("provided"), .fcmToken("fcm")]

        let merged = AppInfoTool.merging(recorded, with: provided)

        #expect(merged.map { $0.row() } == [
            AppInfoRow(title: "APNs token", value: "provided"),
            AppInfoRow(title: "User", value: "42"),
            AppInfoRow(title: "FCM token", value: "fcm")
        ])
    }

    @Test("No providers gives nothing")
    func noProviders() async {
        #expect(await AppInfoTool.provided().isEmpty)
    }

    // MARK: - Sections

    @Test("App section comes from the Info.plist values")
    func appSection() throws {
        let info: [String: Any] = [
            "CFBundleName": "Emergency",
            "CFBundleShortVersionString": "5.6.0",
            "CFBundleVersion": "1234",
            "CFBundleIdentifier": "com.cube.arc.hazards"
        ]

        let app = try #require(AppInfoTool.sections(infoDictionary: info, fromApp: []).dropFirst().first)

        #expect(app.title == "App")
        #expect(app.rows == [
            AppInfoRow(title: "Name", value: "Emergency"),
            AppInfoRow(title: "Version", value: "5.6.0"),
            AppInfoRow(title: "Build", value: "1234"),
            AppInfoRow(title: "Bundle ID", value: "com.cube.arc.hazards")
        ])
    }

    @Test("Device section names the Simulator's model")
    func deviceSection() throws {
        let device = try #require(AppInfoTool.sections(infoDictionary: [:], fromApp: []).last)

        #expect(device.title == "Device")
        #expect(device.rows.map(\.title) == ["Model", "iOS", "Locale", "Time zone"])
        #expect(device.rows[0].value.hasSuffix("(Simulator)"))
    }

    @Test("From the app comes first, in order")
    func recordedSection() throws {
        let recorded: [AppInfo] = [.custom(title: "A", value: "1"), .apnsToken("ff")]

        let section = try #require(AppInfoTool.sections(infoDictionary: [:], fromApp: recorded).first)

        #expect(section.title == "From the app")
        #expect(section.rows.map(\.title) == ["A", "APNs token"])
        #expect(AppInfoTool.sections(infoDictionary: [:], fromApp: recorded).map(\.title) == ["From the app", "App", "Device"])
    }

    // MARK: - Copy all

    @Test("Copy all lists each non-empty section as Title: value lines")
    func copyAllText() {
        let sections = [
            AppInfoSection(title: "App", rows: [AppInfoRow(title: "Version", value: "1.0"), AppInfoRow(title: "Build", value: "7")]),
            AppInfoSection(title: "From the app", rows: []),
            AppInfoSection(title: "Device", rows: [AppInfoRow(title: "iOS", value: "26.0")])
        ]

        #expect(AppInfoTool.copyAllText(of: sections) == "App\nVersion: 1.0\nBuild: 7\n\nDevice\niOS: 26.0")
    }

    @Test("Listed first in the General section")
    func registeredFirst() {
        #expect(BaymaxServices().diagnosticTools.first is AppInfoTool)
    }
}
