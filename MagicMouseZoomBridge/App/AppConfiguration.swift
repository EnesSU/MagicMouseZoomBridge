//
//  AppConfiguration.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

import CoreGraphics
import Foundation

enum ActivationModifier: String, CaseIterable {
    case option
    case control
    case command
    case shift

    var title: String {
        switch self {
        case .option:
            return "Option"
        case .control:
            return "Control"
        case .command:
            return "Command"
        case .shift:
            return "Shift"
        }
    }

    var eventFlagMask: UInt64 {
        switch self {
        case .option:
            return CGEventFlags.maskAlternate.rawValue
        case .control:
            return CGEventFlags.maskControl.rawValue
        case .command:
            return CGEventFlags.maskCommand.rawValue
        case .shift:
            return CGEventFlags.maskShift.rawValue
        }
    }
}

struct AppConfiguration: Equatable {
    var enabled: Bool = true
    var activationModifier: ActivationModifier = .option
    var sensitivity: Double = 0.006
    var invertDirection: Bool = false
    var eraseModifiers: Bool = true
    var debugLogging: Bool = false
    var deadZone: Double = 0.001
    var maxScale: Double = 0.08
    var gestureEndDelaySeconds: Double = 0.150

    var eventTapConfiguration: MMZEventTapConfiguration {
        MMZEventTapConfiguration(
            enabled: enabled,
            activationModifierMask: activationModifier.eventFlagMask,
            sensitivity: sensitivity,
            invertDirection: invertDirection,
            eraseModifiers: eraseModifiers,
            debugLogging: debugLogging,
            deadZone: deadZone,
            maxScale: maxScale,
            gestureEndDelaySeconds: gestureEndDelaySeconds
        )
    }
}

final class AppConfigurationStore {
    private enum Key {
        static let enabled = "enabled"
        static let activationModifier = "activationModifier"
        static let sensitivity = "sensitivity"
        static let invertDirection = "invertDirection"
        static let eraseModifiers = "eraseModifiers"
        static let debugLogging = "debugLogging"
    }

    private let defaults: UserDefaults
    var onChange: ((AppConfiguration) -> Void)?

    private(set) var configuration: AppConfiguration {
        didSet {
            guard oldValue != configuration else {
                return
            }

            save()
            onChange?(configuration)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.configuration = AppConfiguration()
        self.configuration = Self.load(from: defaults)
    }

    func setEnabled(_ enabled: Bool) {
        configuration.enabled = enabled
    }

    func setActivationModifier(_ modifier: ActivationModifier) {
        configuration.activationModifier = modifier
    }

    func setSensitivity(_ sensitivity: Double) {
        configuration.sensitivity = sensitivity
    }

    func setInvertDirection(_ invertDirection: Bool) {
        configuration.invertDirection = invertDirection
    }

    func setEraseModifiers(_ eraseModifiers: Bool) {
        configuration.eraseModifiers = eraseModifiers
    }

    func setDebugLogging(_ debugLogging: Bool) {
        configuration.debugLogging = debugLogging
    }

    private static func load(from defaults: UserDefaults) -> AppConfiguration {
        var configuration = AppConfiguration()

        if defaults.object(forKey: Key.enabled) != nil {
            configuration.enabled = defaults.bool(forKey: Key.enabled)
        }

        if let rawModifier = defaults.string(forKey: Key.activationModifier),
           let modifier = ActivationModifier(rawValue: rawModifier) {
            configuration.activationModifier = modifier
        }

        let sensitivity = defaults.double(forKey: Key.sensitivity)
        if sensitivity > 0.0 {
            configuration.sensitivity = sensitivity
        }

        if defaults.object(forKey: Key.invertDirection) != nil {
            configuration.invertDirection = defaults.bool(forKey: Key.invertDirection)
        }

        if defaults.object(forKey: Key.eraseModifiers) != nil {
            configuration.eraseModifiers = defaults.bool(forKey: Key.eraseModifiers)
        }

        if defaults.object(forKey: Key.debugLogging) != nil {
            configuration.debugLogging = defaults.bool(forKey: Key.debugLogging)
        }

        return configuration
    }

    private func save() {
        defaults.set(configuration.enabled, forKey: Key.enabled)
        defaults.set(configuration.activationModifier.rawValue, forKey: Key.activationModifier)
        defaults.set(configuration.sensitivity, forKey: Key.sensitivity)
        defaults.set(configuration.invertDirection, forKey: Key.invertDirection)
        defaults.set(configuration.eraseModifiers, forKey: Key.eraseModifiers)
        defaults.set(configuration.debugLogging, forKey: Key.debugLogging)
    }
}
