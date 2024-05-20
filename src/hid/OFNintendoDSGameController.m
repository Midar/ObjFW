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

#import "OFNintendoDSGameController.h"
#import "OFArray.h"
#import "OFSet.h"

#import "OFOutOfRangeException.h"

#define asm __asm__
#include <nds.h>
#undef asm

static OFArray OF_GENERIC(OFGameController *) *controllers;

@implementation OFNintendoDSGameController
+ (void)initialize
{
	void *pool;

	if (self != [OFNintendoDSGameController class])
		return;

	pool = objc_autoreleasePoolPush();
	controllers = [[OFArray alloc] initWithObject:
	    [[[OFNintendoDSGameController alloc] init] autorelease]];
	objc_autoreleasePoolPop(pool);
}

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	return controllers;
}

- (instancetype)init
{
	self = [super init];

	@try {
		_pressedButtons = [[OFMutableSet alloc] initWithCapacity: 12];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_pressedButtons release];

	[super dealloc];
}

- (void)retrieveState
{
	uint32 keys;

	scanKeys();
	keys = keysCurrent();

	[_pressedButtons removeAllObjects];

	if (keys & KEY_X)
		[_pressedButtons addObject: OFGameControllerNorthButton];
	if (keys & KEY_B)
		[_pressedButtons addObject: OFGameControllerSouthButton];
	if (keys & KEY_Y)
		[_pressedButtons addObject: OFGameControllerWestButton];
	if (keys & KEY_A)
		[_pressedButtons addObject: OFGameControllerEastButton];
	if (keys & KEY_L)
		[_pressedButtons addObject: OFGameControllerLeftShoulderButton];
	if (keys & KEY_R)
		[_pressedButtons addObject:
		    OFGameControllerRightShoulderButton];
	if (keys & KEY_UP)
		[_pressedButtons addObject: OFGameControllerDPadUpButton];
	if (keys & KEY_DOWN)
		[_pressedButtons addObject: OFGameControllerDPadDownButton];
	if (keys & KEY_LEFT)
		[_pressedButtons addObject: OFGameControllerDPadLeftButton];
	if (keys & KEY_RIGHT)
		[_pressedButtons addObject: OFGameControllerDPadRightButton];
	if (keys & KEY_START)
		[_pressedButtons addObject: OFGameControllerStartButton];
	if (keys & KEY_SELECT)
		[_pressedButtons addObject: OFGameControllerSelectButton];
}

- (OFString *)name
{
	return @"Nintendo DS";
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	return [OFSet setWithObjects:
	    OFGameControllerNorthButton,
	    OFGameControllerSouthButton,
	    OFGameControllerWestButton,
	    OFGameControllerEastButton,
	    OFGameControllerLeftShoulderButton,
	    OFGameControllerRightShoulderButton,
	    OFGameControllerDPadUpButton,
	    OFGameControllerDPadDownButton,
	    OFGameControllerDPadLeftButton,
	    OFGameControllerDPadRightButton,
	    OFGameControllerStartButton,
	    OFGameControllerSelectButton, nil];
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	return [[_pressedButtons copy] autorelease];
}

- (bool)hasLeftAnalogStick
{
	return false;
}

- (bool)hasRightAnalogStick
{
	return false;
}
@end