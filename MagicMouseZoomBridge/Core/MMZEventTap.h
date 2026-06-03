//
//  MMZEventTap.h
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

#ifndef MMZEventTap_h
#define MMZEventTap_h

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    bool enabled;
    uint64_t activationModifierMask;
    double sensitivity;
    bool invertDirection;
    bool eraseModifiers;
    bool debugLogging;
    double deadZone;
    double maxScale;
    double gestureEndDelaySeconds;
} MMZEventTapConfiguration;

#ifdef __cplusplus
extern "C" {
#endif

bool MMZEventTapStart(MMZEventTapConfiguration configuration);
void MMZEventTapStop(void);
bool MMZEventTapIsRunning(void);
void MMZEventTapUpdateConfiguration(MMZEventTapConfiguration configuration);
bool MMZEventTapAccessibilityTrusted(bool prompt);
double MMZComputeZoomScale(double deltaY, double sensitivity, bool invertDirection, double deadZone, double maxScale);

#ifdef __cplusplus
}
#endif

#endif /* MMZEventTap_h */
