//
//  StatusBarController.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let configurationStore: AppConfigurationStore
    private let eventBridgeController: EventBridgeController

    init(configurationStore: AppConfigurationStore, eventBridgeController: EventBridgeController) {
        self.configurationStore = configurationStore
        self.eventBridgeController = eventBridgeController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "plus.magnifyingglass", accessibilityDescription: "Magic Mouse Zoom Bridge")
            button.image?.isTemplate = true
            button.title = button.image == nil ? "MMZ" : ""
        }

        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let configuration = configurationStore.configuration

        let enabledItem = NSMenuItem(
            title: "Enable Magic Mouse Zoom Bridge",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = configuration.enabled ? .on : .off
        menu.addItem(enabledItem)

        let runningTitle = eventBridgeController.isRunning ? "Event Tap: Running" : "Event Tap: Not Running"
        let runningItem = NSMenuItem(title: runningTitle, action: nil, keyEquivalent: "")
        runningItem.isEnabled = false
        menu.addItem(runningItem)

        menu.addItem(.separator())
        menu.addItem(activationMenuItem(configuration: configuration))
        menu.addItem(sensitivityMenuItem(configuration: configuration))

        let invertItem = NSMenuItem(title: "Invert Direction", action: #selector(toggleInvertDirection), keyEquivalent: "")
        invertItem.target = self
        invertItem.state = configuration.invertDirection ? .on : .off
        menu.addItem(invertItem)

        let eraseItem = NSMenuItem(title: "Erase Modifiers", action: #selector(toggleEraseModifiers), keyEquivalent: "")
        eraseItem.target = self
        eraseItem.state = configuration.eraseModifiers ? .on : .off
        menu.addItem(eraseItem)

        let debugItem = NSMenuItem(title: "Debug Logging", action: #selector(toggleDebugLogging), keyEquivalent: "")
        debugItem.target = self
        debugItem.state = configuration.debugLogging ? .on : .off
        menu.addItem(debugItem)

        menu.addItem(.separator())

        let accessibilityTitle = PermissionController.accessibilityTrusted
            ? "Accessibility: Allowed"
            : "Accessibility: Required"
        let accessibilityStatusItem = NSMenuItem(title: accessibilityTitle, action: nil, keyEquivalent: "")
        accessibilityStatusItem.isEnabled = false
        menu.addItem(accessibilityStatusItem)

        let requestAccessibilityItem = NSMenuItem(
            title: "Request Accessibility Permission",
            action: #selector(requestAccessibilityPermission),
            keyEquivalent: ""
        )
        requestAccessibilityItem.target = self
        menu.addItem(requestAccessibilityItem)

        let openInputMonitoringItem = NSMenuItem(
            title: "Open Input Monitoring Settings",
            action: #selector(openInputMonitoringSettings),
            keyEquivalent: ""
        )
        openInputMonitoringItem.target = self
        menu.addItem(openInputMonitoringItem)

        let restartItem = NSMenuItem(title: "Restart Event Tap", action: #selector(restartEventTap), keyEquivalent: "")
        restartItem.target = self
        menu.addItem(restartItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func activationMenuItem(configuration: AppConfiguration) -> NSMenuItem {
        let item = NSMenuItem(title: "Activation: \(configuration.activationModifier.title)", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for modifier in ActivationModifier.allCases {
            let modifierItem = NSMenuItem(title: modifier.title, action: #selector(selectActivationModifier(_:)), keyEquivalent: "")
            modifierItem.target = self
            modifierItem.representedObject = modifier.rawValue
            modifierItem.state = configuration.activationModifier == modifier ? .on : .off
            submenu.addItem(modifierItem)
        }

        item.submenu = submenu
        return item
    }

    private func sensitivityMenuItem(configuration: AppConfiguration) -> NSMenuItem {
        let item = NSMenuItem(title: "Sensitivity: \(sensitivityTitle(configuration.sensitivity))", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for option in SensitivityOption.allCases {
            let optionItem = NSMenuItem(title: option.title, action: #selector(selectSensitivity(_:)), keyEquivalent: "")
            optionItem.target = self
            optionItem.representedObject = option.rawValue
            optionItem.state = abs(configuration.sensitivity - option.value) < 0.000_001 ? .on : .off
            submenu.addItem(optionItem)
        }

        item.submenu = submenu
        return item
    }

    private func sensitivityTitle(_ value: Double) -> String {
        SensitivityOption.allCases.first { abs($0.value - value) < 0.000_001 }?.title ?? String(format: "%.3f", value)
    }

    @objc private func toggleEnabled() {
        configurationStore.setEnabled(!configurationStore.configuration.enabled)
    }

    @objc private func selectActivationModifier(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let modifier = ActivationModifier(rawValue: rawValue) else {
            return
        }

        configurationStore.setActivationModifier(modifier)
    }

    @objc private func selectSensitivity(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let option = SensitivityOption(rawValue: rawValue) else {
            return
        }

        configurationStore.setSensitivity(option.value)
    }

    @objc private func toggleInvertDirection() {
        configurationStore.setInvertDirection(!configurationStore.configuration.invertDirection)
    }

    @objc private func toggleEraseModifiers() {
        configurationStore.setEraseModifiers(!configurationStore.configuration.eraseModifiers)
    }

    @objc private func toggleDebugLogging() {
        configurationStore.setDebugLogging(!configurationStore.configuration.debugLogging)
    }

    @objc private func requestAccessibilityPermission() {
        PermissionController.requestAccessibilityPermission()
        PermissionController.openAccessibilitySettings()
    }

    @objc private func openInputMonitoringSettings() {
        PermissionController.openInputMonitoringSettings()
    }

    @objc private func restartEventTap() {
        eventBridgeController.stop()
        eventBridgeController.start(configuration: configurationStore.configuration)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private enum SensitivityOption: String, CaseIterable {
    case low
    case medium
    case high
    case veryHigh

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }

    var value: Double {
        switch self {
        case .low:
            return 0.003
        case .medium:
            return 0.006
        case .high:
            return 0.010
        case .veryHigh:
            return 0.020
        }
    }
}
