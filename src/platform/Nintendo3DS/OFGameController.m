/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFGameController.h"
#import "OFArray.h"
#import "OFSet.h"

#import "OFOutOfRangeException.h"

#define id id_3ds
#include <3ds.h>
#undef id

@interface OFGameController ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
@end

static OFArray OF_GENERIC(OFGameController *) *controllers;

static void
initControllers(void)
{
	void *pool = objc_autoreleasePoolPush();

	controllers = [[OFArray alloc] initWithObject:
	    [[[OFGameController alloc] of_init] autorelease]];

	objc_autoreleasePoolPop(pool);
}

@implementation OFGameController
@dynamic rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	static OFOnceControl onceControl = OFOnceControlInitValue;

	OFOnce(&onceControl, initControllers);

	return [[controllers retain] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (OFSet *)buttons
{
	return [OFSet setWithObjects: OFGameControllerButtonA,
	    OFGameControllerButtonB, OFGameControllerButtonSelect,
	    OFGameControllerButtonStart, OFGameControllerButtonDPadRight,
	    OFGameControllerButtonDPadLeft, OFGameControllerButtonDPadUp,
	    OFGameControllerButtonDPadDown, OFGameControllerButtonR,
	    OFGameControllerButtonL, OFGameControllerButtonX,
	    OFGameControllerButtonY, OFGameControllerButtonZL,
	    OFGameControllerButtonZR, OFGameControllerButtonCPadRight,
	    OFGameControllerButtonCPadLeft, OFGameControllerButtonCPadUp,
	    OFGameControllerButtonCPadDown, nil];
}

- (OFSet *)pressedButtons
{
	OFMutableSet *pressedButtons = [OFMutableSet setWithCapacity: 18];
	u32 keys;

	hidScanInput();
	keys = hidKeysHeld();

	if (keys & KEY_A)
		[pressedButtons addObject: OFGameControllerButtonA];
	if (keys & KEY_B)
		[pressedButtons addObject: OFGameControllerButtonB];
	if (keys & KEY_SELECT)
		[pressedButtons addObject: OFGameControllerButtonSelect];
	if (keys & KEY_START)
		[pressedButtons addObject: OFGameControllerButtonStart];
	if (keys & KEY_DRIGHT)
		[pressedButtons addObject: OFGameControllerButtonDPadRight];
	if (keys & KEY_DLEFT)
		[pressedButtons addObject: OFGameControllerButtonDPadLeft];
	if (keys & KEY_DUP)
		[pressedButtons addObject: OFGameControllerButtonDPadUp];
	if (keys & KEY_DDOWN)
		[pressedButtons addObject: OFGameControllerButtonDPadDown];
	if (keys & KEY_R)
		[pressedButtons addObject: OFGameControllerButtonR];
	if (keys & KEY_L)
		[pressedButtons addObject: OFGameControllerButtonL];
	if (keys & KEY_X)
		[pressedButtons addObject: OFGameControllerButtonX];
	if (keys & KEY_Y)
		[pressedButtons addObject: OFGameControllerButtonY];
	if (keys & KEY_ZL)
		[pressedButtons addObject: OFGameControllerButtonZL];
	if (keys & KEY_ZR)
		[pressedButtons addObject: OFGameControllerButtonZR];
	if (keys & KEY_CSTICK_RIGHT)
		[pressedButtons addObject: OFGameControllerButtonCPadRight];
	if (keys & KEY_CSTICK_LEFT)
		[pressedButtons addObject: OFGameControllerButtonCPadLeft];
	if (keys & KEY_CSTICK_UP)
		[pressedButtons addObject: OFGameControllerButtonCPadUp];
	if (keys & KEY_CSTICK_DOWN)
		[pressedButtons addObject: OFGameControllerButtonCPadDown];

	[pressedButtons makeImmutable];

	return pressedButtons;
}

- (bool)hasLeftAnalogStick
{
	return true;
}

- (bool)hasRightAnalogStick
{
	return false;
}

- (OFPoint)leftAnalogStickPosition
{
	circlePosition pos;
	hidCircleRead(&pos);

	return OFMakePoint(
	    (float)pos.dx / (pos.dx < 0 ? -INT16_MIN : INT16_MAX),
	    (float)pos.dy / (pos.dy < 0 ? -INT16_MIN : INT16_MAX));
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
