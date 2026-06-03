//
//  PermissionController.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

import AppKit
import Foundation

enum PermissionController {
    static var accessibilityTrusted: Bool {
        MMZEventTapAccessibilityTrusted(false)
    }

    static func requestAccessibilityPermission() {
        _ = MMZEventTapAccessibilityTrusted(true)
    }

    static func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
