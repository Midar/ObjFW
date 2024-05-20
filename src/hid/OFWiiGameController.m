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

#import "OFWiiGameController.h"
#import "OFMutableSet.h"

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"
#import "OFReadFailedException.h"

#define asm __asm__
#include <wiiuse/wpad.h>
#undef asm

static float
scale(float value, float min, float max, float center)
{
	if (value < min)
		value = min;
	if (value > max)
		value = max;

	if (value >= center)
		return (value - center) / (max - center);
	else
		return (value - center) / (center - min);
}

@implementation OFWiiGameController
+ (void)initialize
{
	if (self != [OFWiiGameController class])
		return;

	if (WPAD_Init() != WPAD_ERR_NONE)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (int32_t i = 0; i < WPAD_MAX_WIIMOTES; i++) {
		uint32_t type;

		if (WPAD_Probe(i, &type) == WPAD_ERR_NONE &&
		    (type == WPAD_EXP_NONE || type == WPAD_EXP_NUNCHUK))
			[controllers addObject: [[[OFWiiGameController alloc]
			    of_initWithIndex: i
					type: type] autorelease]];
	}

	[controllers makeImmutable];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)of_initWithIndex: (int32_t)index type: (uint32_t)type
{
	self = [super init];

	@try {
		_index = index;
		_type = type;

		_pressedButtons = [[OFMutableSet alloc] initWithCapacity: 13];

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
	WPADData *data;

	if (WPAD_ReadPending(_index, NULL) < WPAD_ERR_NONE)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: sizeof(WPADData)
				  errNo: 0];

	data = WPAD_Data(_index);

	[_pressedButtons removeAllObjects];

	if (data->btns_h & WPAD_BUTTON_A)
		[_pressedButtons addObject: OFGameControllerEastButton];
	if (data->btns_h & WPAD_BUTTON_B)
		[_pressedButtons addObject: OFGameControllerRightTriggerButton];
	if (data->btns_h & WPAD_BUTTON_1)
		[_pressedButtons addObject: OFGameControllerWestButton];
	if (data->btns_h & WPAD_BUTTON_2)
		[_pressedButtons addObject: OFGameControllerSouthButton];
	if (data->btns_h & WPAD_BUTTON_UP)
		[_pressedButtons addObject: OFGameControllerDPadUpButton];
	if (data->btns_h & WPAD_BUTTON_DOWN)
		[_pressedButtons addObject: OFGameControllerDPadDownButton];
	if (data->btns_h & WPAD_BUTTON_LEFT)
		[_pressedButtons addObject: OFGameControllerDPadLeftButton];
	if (data->btns_h & WPAD_BUTTON_RIGHT)
		[_pressedButtons addObject: OFGameControllerDPadRightButton];
	if (data->btns_h & WPAD_BUTTON_PLUS)
		[_pressedButtons addObject: OFGameControllerStartButton];
	if (data->btns_h & WPAD_BUTTON_MINUS)
		[_pressedButtons addObject: OFGameControllerSelectButton];
	if (data->btns_h & WPAD_BUTTON_HOME)
		[_pressedButtons addObject: OFGameControllerHomeButton];

	if (_type == WPAD_EXP_NUNCHUK) {
		joystick_t *js;

		if (data->btns_h & WPAD_NUNCHUK_BUTTON_C)
			[_pressedButtons addObject:
			    OFGameControllerLeftShoulderButton];
		if (data->btns_h & WPAD_NUNCHUK_BUTTON_Z)
			[_pressedButtons addObject:
			    OFGameControllerLeftTriggerButton];

		js = &data->exp.nunchuk.js;
		_leftAnalogStickPosition = OFMakePoint(
		    scale(js->pos.x, js->min.x, js->max.x, js->center.x),
		    -scale(js->pos.y, js->min.y, js->max.y, js->center.y));
	}
}

- (OFString *)name
{
	if (_type == WPAD_EXP_NUNCHUK)
		return @"Wiimote with Nunchuk";

	return @"Wiimote";
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	OFMutableSet *buttons = [OFMutableSet setWithCapacity: 13];

	[buttons addObject: OFGameControllerSouthButton];
	[buttons addObject: OFGameControllerRightTriggerButton];
	[buttons addObject: OFGameControllerWestButton];
	[buttons addObject: OFGameControllerEastButton];
	[buttons addObject: OFGameControllerDPadUpButton];
	[buttons addObject: OFGameControllerDPadDownButton];
	[buttons addObject: OFGameControllerDPadLeftButton];
	[buttons addObject: OFGameControllerDPadRightButton];
	[buttons addObject: OFGameControllerStartButton];
	[buttons addObject: OFGameControllerSelectButton];
	[buttons addObject: OFGameControllerHomeButton];

	if (_type == WPAD_EXP_NUNCHUK) {
		[buttons addObject: OFGameControllerLeftShoulderButton];
		[buttons addObject: OFGameControllerLeftTriggerButton];
	}

	[buttons makeImmutable];

	return buttons;
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	return [[_pressedButtons copy] autorelease];
}

- (bool)hasLeftAnalogStick
{
	return (_type == WPAD_EXP_NUNCHUK);
}

- (bool)hasRightAnalogStick
{
	return false;
}

- (OFPoint)leftAnalogStickPosition
{
	if (_type != WPAD_EXP_NUNCHUK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return _leftAnalogStickPosition;
}
@end
