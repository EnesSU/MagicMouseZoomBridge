//
//  MMZCGEventSPI.h
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

#ifndef MMZCGEventSPI_h
#define MMZCGEventSPI_h

#include <CoreGraphics/CoreGraphics.h>

/*
 These CoreGraphics values are private SPI observed in existing event-level
 zoom utilities. Keep them isolated so the blast radius is small if macOS
 changes the fields in a future release.
 */
#define MMZ_CG_EVENT_GESTURE 29
#define MMZ_CG_GESTURE_EVENT_HID_TYPE 110
#define MMZ_CG_GESTURE_EVENT_ZOOM_VALUE 113
#define MMZ_CG_GESTURE_EVENT_PHASE 132

#define MMZ_IOHID_EVENT_TYPE_ZOOM 8

#define MMZ_EVENT_PHASE_BEGAN 0x1
#define MMZ_EVENT_PHASE_CHANGED 0x2
#define MMZ_EVENT_PHASE_ENDED 0x4
#define MMZ_EVENT_PHASE_CANCELLED 0x8

#endif /* MMZCGEventSPI_h */
