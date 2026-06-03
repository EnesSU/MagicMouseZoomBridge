//
//  EventBridgeController.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

import Foundation

final class EventBridgeController {
    private(set) var lastStartSucceeded = false

    func start(configuration: AppConfiguration) {
        MMZEventTapUpdateConfiguration(configuration.eventTapConfiguration)
        lastStartSucceeded = MMZEventTapStart(configuration.eventTapConfiguration)
    }

    func stop() {
        MMZEventTapStop()
        lastStartSucceeded = false
    }

    func update(configuration: AppConfiguration) {
        MMZEventTapUpdateConfiguration(configuration.eventTapConfiguration)

        if configuration.enabled {
            start(configuration: configuration)
        } else {
            stop()
        }
    }

    var isRunning: Bool {
        MMZEventTapIsRunning()
    }
}
