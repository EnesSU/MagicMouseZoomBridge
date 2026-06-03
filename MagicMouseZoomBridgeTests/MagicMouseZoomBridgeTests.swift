//
//  MagicMouseZoomBridgeTests.swift
//  MagicMouseZoomBridgeTests
//
//  Created by Enes Akkus on 3.06.2026.
//

import XCTest
@testable import MagicMouseZoomBridge

final class MagicMouseZoomBridgeTests: XCTestCase {
    func testDefaultConfigurationMatchesDesignPoC() throws {
        let configuration = AppConfiguration()

        XCTAssertTrue(configuration.enabled)
        XCTAssertEqual(configuration.activationModifier, .option)
        XCTAssertEqual(configuration.sensitivity, 0.006, accuracy: 0.000_001)
        XCTAssertFalse(configuration.invertDirection)
        XCTAssertTrue(configuration.eraseModifiers)
        XCTAssertEqual(configuration.deadZone, 0.001, accuracy: 0.000_001)
        XCTAssertEqual(configuration.maxScale, 0.08, accuracy: 0.000_001)
        XCTAssertEqual(configuration.gestureEndDelaySeconds, 0.150, accuracy: 0.000_001)
    }

    func testZoomScaleClampsTotalMovementAndInverts() throws {
        XCTAssertEqual(
            MMZComputeZoomScale(100.0, 0.006, false, 0.001, 0.08),
            0.60,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            MMZComputeZoomScale(100.0, 0.006, true, 0.001, 0.08),
            -0.60,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            MMZComputeZoomScale(1000.0, 0.006, false, 0.001, 0.08),
            0.64,
            accuracy: 0.000_001
        )
    }

    func testZoomScaleDeadZoneReturnsZero() throws {
        XCTAssertEqual(
            MMZComputeZoomScale(0.1, 0.006, false, 0.001, 0.08),
            0.0,
            accuracy: 0.000_001
        )
    }
}
