//
//  MMZEventTap.c
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

#include "MMZEventTap.h"
#include "MMZCGEventSPI.h"

#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach_time.h>
#include <math.h>
#include <stdio.h>

static const MMZEventTapConfiguration MMZDefaultConfiguration = {
    .enabled = true,
    .activationModifierMask = kCGEventFlagMaskAlternate,
    .sensitivity = 0.006,
    .invertDirection = false,
    .eraseModifiers = true,
    .debugLogging = false,
    .deadZone = 0.001,
    .maxScale = 0.08,
    .gestureEndDelaySeconds = 0.150
};

static MMZEventTapConfiguration gConfiguration = {
    .enabled = true,
    .activationModifierMask = kCGEventFlagMaskAlternate,
    .sensitivity = 0.006,
    .invertDirection = false,
    .eraseModifiers = true,
    .debugLogging = false,
    .deadZone = 0.001,
    .maxScale = 0.08,
    .gestureEndDelaySeconds = 0.150
};

static CFMachPortRef gEventTap = NULL;
static CFRunLoopSourceRef gRunLoopSource = NULL;
static CFRunLoopTimerRef gGestureEndTimer = NULL;
static bool gZoomSessionActive = false;
static CGPoint gLastMouseLocation = {0.0, 0.0};
static uint64_t gLastSyntheticTimestamp = 0;

// Each synthetic gesture event must carry a strictly increasing timestamp.
// When several magnify events share a timestamp (for example the chunks of a
// single large scroll), the window server coalesces them into one step, so the
// zoom appears to advance by only a single notch instead of continuously.
static uint64_t MMZNextEventTimestamp(void) {
    uint64_t now = mach_absolute_time();
    if (now <= gLastSyntheticTimestamp) {
        now = gLastSyntheticTimestamp + 1;
    }
    gLastSyntheticTimestamp = now;
    return now;
}

static void MMZLog(const char *message) {
    if (gConfiguration.debugLogging) {
        fprintf(stderr, "[MagicMouseZoomBridge] %s\n", message);
    }
}

static void MMZLogEvent(double deltaY, double scale, const char *phase) {
    if (gConfiguration.debugLogging) {
        fprintf(stderr, "[MagicMouseZoomBridge] deltaY=%.4f scale=%.4f phase=%s\n", deltaY, scale, phase);
    }
}

double MMZComputeZoomScale(double deltaY, double sensitivity, bool invertDirection, double deadZone, double maxScale) {
    double scale = deltaY * sensitivity;

    if (invertDirection) {
        scale = -scale;
    }

    double maxTotalScale = maxScale * 8.0;
    if (scale > maxTotalScale) {
        scale = maxTotalScale;
    } else if (scale < -maxTotalScale) {
        scale = -maxTotalScale;
    }

    if (fabs(scale) < deadZone) {
        return 0.0;
    }

    return scale;
}

static double MMZScrollDeltaY(CGEventRef event) {
    double fixedPointDelta = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis1);
    if (fixedPointDelta != 0.0) {
        return fixedPointDelta;
    }

    double pointDelta = (double)CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1);
    if (pointDelta != 0.0) {
        return pointDelta;
    }

    double lineDelta = (double)CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1);
    if (lineDelta != 0.0) {
        return lineDelta;
    }

    return 0.0;
}

static CGEventRef MMZCreateZoomGestureEvent(CGEventRef sourceEvent, double scale, int64_t phase, CGPoint location) {
    CGEventSourceRef source = sourceEvent != NULL ? CGEventCreateSourceFromEvent(sourceEvent) : NULL;
    CGEventRef gestureEvent = CGEventCreate(source);
    if (source != NULL) {
        CFRelease(source);
    }

    if (gestureEvent == NULL) {
        return NULL;
    }

    CGEventSetType(gestureEvent, (CGEventType)MMZ_CG_EVENT_GESTURE);
    CGEventSetIntegerValueField(gestureEvent, (CGEventField)MMZ_CG_GESTURE_EVENT_HID_TYPE, MMZ_IOHID_EVENT_TYPE_ZOOM);
    CGEventSetDoubleValueField(gestureEvent, (CGEventField)MMZ_CG_GESTURE_EVENT_ZOOM_VALUE, scale);
    CGEventSetIntegerValueField(gestureEvent, (CGEventField)MMZ_CG_GESTURE_EVENT_PHASE, phase);
    CGEventSetLocation(gestureEvent, location);

    if (gConfiguration.eraseModifiers) {
        CGEventSetFlags(gestureEvent, 0);
    } else if (sourceEvent != NULL) {
        CGEventSetFlags(gestureEvent, CGEventGetFlags(sourceEvent));
    }

    CGEventSetTimestamp(gestureEvent, MMZNextEventTimestamp());

    return gestureEvent;
}

static void MMZPostZoomGesture(CGEventRef sourceEvent, double scale, int64_t phase, CGPoint location) {
    CGEventRef gestureEvent = MMZCreateZoomGestureEvent(sourceEvent, scale, phase, location);
    if (gestureEvent == NULL) {
        MMZLog("failed to create synthetic gesture event");
        return;
    }

    CGEventPost(kCGSessionEventTap, gestureEvent);
    CFRelease(gestureEvent);
}

static void MMZPostZoomChangeEvents(CGEventRef sourceEvent, double deltaY, double scale, CGPoint location) {
    double maxPerEvent = gConfiguration.maxScale > 0.0 ? gConfiguration.maxScale : MMZDefaultConfiguration.maxScale;
    double remaining = scale;

    while (fabs(remaining) > maxPerEvent) {
        double chunk = remaining > 0.0 ? maxPerEvent : -maxPerEvent;
        MMZPostZoomGesture(sourceEvent, chunk, MMZ_EVENT_PHASE_CHANGED, location);
        MMZLogEvent(deltaY, chunk, "changed");
        remaining -= chunk;
    }

    if (remaining != 0.0) {
        MMZPostZoomGesture(sourceEvent, remaining, MMZ_EVENT_PHASE_CHANGED, location);
        MMZLogEvent(deltaY, remaining, "changed");
    }
}

static void MMZInvalidateGestureEndTimer(void) {
    if (gGestureEndTimer != NULL) {
        CFRunLoopTimerInvalidate(gGestureEndTimer);
        CFRelease(gGestureEndTimer);
        gGestureEndTimer = NULL;
    }
}

static void MMZEndZoomSession(void) {
    MMZInvalidateGestureEndTimer();

    if (!gZoomSessionActive) {
        return;
    }

    MMZPostZoomGesture(NULL, 0.0, MMZ_EVENT_PHASE_ENDED, gLastMouseLocation);
    gZoomSessionActive = false;
    MMZLogEvent(0.0, 0.0, "ended");
}

static void MMZGestureEndTimerCallback(CFRunLoopTimerRef timer, void *info) {
    (void)timer;
    (void)info;
    MMZEndZoomSession();
}

static void MMZScheduleGestureEndTimer(void) {
    MMZInvalidateGestureEndTimer();

    double delay = gConfiguration.gestureEndDelaySeconds > 0.0
        ? gConfiguration.gestureEndDelaySeconds
        : MMZDefaultConfiguration.gestureEndDelaySeconds;

    gGestureEndTimer = CFRunLoopTimerCreate(
        kCFAllocatorDefault,
        CFAbsoluteTimeGetCurrent() + delay,
        0.0,
        0,
        0,
        MMZGestureEndTimerCallback,
        NULL
    );

    if (gGestureEndTimer != NULL) {
        CFRunLoopAddTimer(CFRunLoopGetMain(), gGestureEndTimer, kCFRunLoopCommonModes);
    }
}

static bool MMZActivationModifierPressed(CGEventRef event) {
    CGEventFlags flags = CGEventGetFlags(event);
    return (flags & (CGEventFlags)gConfiguration.activationModifierMask) != 0;
}

static CGEventRef MMZEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    (void)proxy;
    (void)userInfo;

    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (gEventTap != NULL) {
            CGEventTapEnable(gEventTap, true);
            MMZLog("event tap re-enabled");
        }
        return event;
    }

    if (type != kCGEventScrollWheel) {
        return event;
    }

    if (!gConfiguration.enabled) {
        MMZEndZoomSession();
        return event;
    }

    if (!MMZActivationModifierPressed(event)) {
        MMZEndZoomSession();
        return event;
    }

    double deltaY = MMZScrollDeltaY(event);
    double scale = MMZComputeZoomScale(
        deltaY,
        gConfiguration.sensitivity,
        gConfiguration.invertDirection,
        gConfiguration.deadZone,
        gConfiguration.maxScale
    );

    if (scale == 0.0) {
        return NULL;
    }

    gLastMouseLocation = CGEventGetLocation(event);

    if (!gZoomSessionActive) {
        MMZPostZoomGesture(event, 0.0, MMZ_EVENT_PHASE_BEGAN, gLastMouseLocation);
        gZoomSessionActive = true;
        MMZLogEvent(deltaY, 0.0, "began");
    }

    MMZPostZoomChangeEvents(event, deltaY, scale, gLastMouseLocation);
    MMZScheduleGestureEndTimer();

    return NULL;
}

bool MMZEventTapStart(MMZEventTapConfiguration configuration) {
    MMZEventTapUpdateConfiguration(configuration);

    if (gEventTap != NULL) {
        CGEventTapEnable(gEventTap, true);
        return true;
    }

    CGEventMask mask = CGEventMaskBit(kCGEventScrollWheel);
    gEventTap = CGEventTapCreate(
        kCGHIDEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,
        mask,
        MMZEventTapCallback,
        NULL
    );

    if (gEventTap == NULL) {
        MMZLog("failed to create event tap; check Accessibility and Input Monitoring permissions");
        return false;
    }

    gRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gEventTap, 0);
    if (gRunLoopSource == NULL) {
        CFRelease(gEventTap);
        gEventTap = NULL;
        MMZLog("failed to create event tap run loop source");
        return false;
    }

    CFRunLoopAddSource(CFRunLoopGetMain(), gRunLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(gEventTap, true);
    MMZLog("event tap started");
    return true;
}

void MMZEventTapStop(void) {
    MMZEndZoomSession();

    if (gRunLoopSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), gRunLoopSource, kCFRunLoopCommonModes);
        CFRelease(gRunLoopSource);
        gRunLoopSource = NULL;
    }

    if (gEventTap != NULL) {
        CFMachPortInvalidate(gEventTap);
        CFRelease(gEventTap);
        gEventTap = NULL;
    }

    MMZLog("event tap stopped");
}

bool MMZEventTapIsRunning(void) {
    return gEventTap != NULL && CGEventTapIsEnabled(gEventTap);
}

void MMZEventTapUpdateConfiguration(MMZEventTapConfiguration configuration) {
    if (configuration.activationModifierMask == 0) {
        configuration.activationModifierMask = MMZDefaultConfiguration.activationModifierMask;
    }

    if (configuration.sensitivity <= 0.0) {
        configuration.sensitivity = MMZDefaultConfiguration.sensitivity;
    }

    if (configuration.deadZone < 0.0) {
        configuration.deadZone = MMZDefaultConfiguration.deadZone;
    }

    if (configuration.maxScale <= 0.0) {
        configuration.maxScale = MMZDefaultConfiguration.maxScale;
    }

    if (configuration.gestureEndDelaySeconds <= 0.0) {
        configuration.gestureEndDelaySeconds = MMZDefaultConfiguration.gestureEndDelaySeconds;
    }

    gConfiguration = configuration;
}

bool MMZEventTapAccessibilityTrusted(bool prompt) {
    const void *keys[] = { kAXTrustedCheckOptionPrompt };
    const void *values[] = { prompt ? kCFBooleanTrue : kCFBooleanFalse };
    CFDictionaryRef options = CFDictionaryCreate(
        kCFAllocatorDefault,
        keys,
        values,
        1,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    bool trusted = AXIsProcessTrustedWithOptions(options);
    CFRelease(options);
    return trusted;
}
