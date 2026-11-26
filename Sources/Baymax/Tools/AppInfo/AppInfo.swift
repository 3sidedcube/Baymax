//
//  AppInfo.swift
//  Baymax
//
//  Created by Szuyun Liang on 04/11/2026.
//  Copyright © 2026 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A value only the app knows, recorded with `AppInfoTool.record(_:)` and shown in the App & device info tool.
public enum AppInfo {

    /// The APNs device token, as hex.
    case apnsToken(String)

    /// The Firebase Cloud Messaging registration token, used to send test messages from the Firebase console.
    case fcmToken(String)

    /// A Firebase App Check token (JWT). Only its expiry is shown; the token itself is never displayed or copied.
    case appCheckToken(String)

    /// Any other value, shown as `title: value`.
    case custom(title: String, value: String)

    /// The APNs device token from `didRegisterForRemoteNotificationsWithDeviceToken`, converted to hex.
    public static func apnsToken(deviceToken: Data) -> AppInfo {
        .apnsToken(deviceToken.map { String(format: "%02x", $0) }.joined())
    }

    /// Recording a value replaces an earlier one with the same identity.
    var identity: String {
        switch self {
        case .apnsToken: "apnsToken"
        case .fcmToken: "fcmToken"
        case .appCheckToken: "appCheckToken"
        case .custom(let title, _): "custom.\(title)"
        }
    }

    /// The row shown on screen and copied.
    func row(now: Date = Date()) -> AppInfoRow {
        switch self {
        case .apnsToken(let token):
            AppInfoRow(title: "APNs token", value: token)
        case .fcmToken(let token):
            AppInfoRow(title: "FCM token", value: token)
        case .appCheckToken(let token):
            AppInfoRow(title: "App Check expiry", value: Self.expiryDescription(ofJWT: token, now: now))
        case .custom(let title, let value):
            AppInfoRow(title: title, value: value)
        }
    }

    /// e.g. "14:05 (in 42 minutes)" or "Expired 14:05 (5 minutes ago)".
    static func expiryDescription(ofJWT token: String, now: Date) -> String {
        guard let expiry = expiry(ofJWT: token) else { return "Unreadable token" }

        let time = expiry.formatted(date: .abbreviated, time: .shortened)
        let relative = RelativeDateTimeFormatter().localizedString(for: expiry, relativeTo: now)
        return expiry > now ? "\(time) (\(relative))" : "Expired \(time) (\(relative))"
    }

    /// The `exp` claim of a JWT, decoded without verifying the signature.
    static func expiry(ofJWT token: String) -> Date? {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return nil }

        var payload = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)

        guard
            let data = Data(base64Encoded: payload),
            let claims = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let exp = claims["exp"] as? TimeInterval
        else { return nil }

        return Date(timeIntervalSince1970: exp)
    }
}

/// One `title: value` line in the App & device info tool.
struct AppInfoRow: Hashable {
    let title: String
    let value: String
}

/// A titled group of rows.
struct AppInfoSection: Hashable {
    let title: String
    let rows: [AppInfoRow]
}
