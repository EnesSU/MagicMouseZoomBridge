//
//  AppDelegate.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let configurationStore = AppConfigurationStore()
    private let eventBridgeController = EventBridgeController()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configurationStore.onChange = { [weak self] configuration in
            self?.eventBridgeController.update(configuration: configuration)
        }

        statusBarController = StatusBarController(
            configurationStore: configurationStore,
            eventBridgeController: eventBridgeController
        )

        PermissionController.requestAccessibilityPermission()
        eventBridgeController.update(configuration: configurationStore.configuration)
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventBridgeController.stop()
    }
}
