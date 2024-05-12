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
#import "OFNumber.h"
#import "OFSet.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#include <xinput.h>

@interface OFGameController ()
- (instancetype)of_initWithIndex: (DWORD)index OF_METHOD_FAMILY(init);
@end

struct XInputCapabilitiesEx {
	XINPUT_CAPABILITIES capabilities;
	WORD vendorID;
	WORD productID;
	WORD versionNumber;
	WORD unknown1;
	DWORD unknown2;
};

static WINAPI DWORD (*XInputGetStateFuncPtr)(DWORD, XINPUT_STATE *);
static WINAPI DWORD (*XInputGetCapabilitiesExFuncPtr)(DWORD, DWORD, DWORD,
    struct XInputCapabilitiesEx *);

@implementation OFGameController
@synthesize vendorID = _vendorID, productID = _productID;
@synthesize leftAnalogStickPosition = _leftAnalogStickPosition;
@synthesize rightAnalogStickPosition = _rightAnalogStickPosition;

+ (void)initialize
{
	HMODULE module;

	if (self != [OFGameController class])
		return;

	if ((module = LoadLibraryA("xinput1_4.dll")) != NULL) {
		XInputGetStateFuncPtr =
		    (WINAPI DWORD (*)(DWORD, XINPUT_STATE *))
		    GetProcAddress(module, "XInputGetState");
		XInputGetCapabilitiesExFuncPtr = (WINAPI DWORD (*)(DWORD, DWORD,
		    DWORD, struct XInputCapabilitiesEx *))
		    GetProcAddress(module, "XInputGetCapabilitiesEx");
	}
}

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];

	if (XInputGetStateFuncPtr != NULL) {
		void *pool = objc_autoreleasePoolPush();

		for (DWORD i = 0; i < XUSER_MAX_COUNT; i++) {
			OFGameController *controller;

			@try {
				controller = [[[OFGameController alloc]
				    of_initWithIndex: i] autorelease];
			} @catch (OFInitializationFailedException *e) {
				/* Controller does not exist. */
				continue;
			}

			[controllers addObject: controller];
		}

		objc_autoreleasePoolPop(pool);
	}

	[controllers makeImmutable];

	return controllers;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithIndex: (DWORD)index
{
	self = [super init];

	@try {
		XINPUT_STATE state = { 0 };

		if (XInputGetStateFuncPtr(index, &state) ==
		    ERROR_DEVICE_NOT_CONNECTED)
			@throw [OFInitializationFailedException exception];

		_index = index;

		if (XInputGetCapabilitiesExFuncPtr != NULL) {
			struct XInputCapabilitiesEx capabilities;

			if (XInputGetCapabilitiesExFuncPtr(1, _index,
			    XINPUT_FLAG_GAMEPAD, &capabilities) ==
			    ERROR_SUCCESS) {
				_vendorID = [[OFNumber alloc]
				    initWithUnsignedShort:
				    capabilities.vendorID];
				_productID = [[OFNumber alloc]
				    initWithUnsignedShort:
				    capabilities.productID];
			}
		}

		_pressedButtons = [[OFMutableSet alloc] initWithCapacity: 16];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_vendorID release];
	[_productID release];
	[_pressedButtons release];

	[super dealloc];
}

- (void)retrieveState
{
	XINPUT_STATE state = { 0 };

	if (XInputGetStateFuncPtr(_index, &state) != ERROR_SUCCESS)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: sizeof(state)
							    errNo: 0];

	[_pressedButtons removeAllObjects];

	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP)
		[_pressedButtons addObject: OFGameControllerButtonDPadUp];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN)
		[_pressedButtons addObject: OFGameControllerButtonDPadDown];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT)
		[_pressedButtons addObject: OFGameControllerButtonDPadLeft];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT)
		[_pressedButtons addObject: OFGameControllerButtonDPadRight];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_START)
		[_pressedButtons addObject: OFGameControllerButtonStart];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_BACK)
		[_pressedButtons addObject: OFGameControllerButtonSelect];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB)
		[_pressedButtons addObject: OFGameControllerButtonLeftStick];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB)
		[_pressedButtons addObject: OFGameControllerButtonRightStick];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER)
		[_pressedButtons addObject: OFGameControllerButtonL];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER)
		[_pressedButtons addObject: OFGameControllerButtonR];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_A)
		[_pressedButtons addObject: OFGameControllerButtonA];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_B)
		[_pressedButtons addObject: OFGameControllerButtonB];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_X)
		[_pressedButtons addObject: OFGameControllerButtonX];
	if (state.Gamepad.wButtons & XINPUT_GAMEPAD_Y)
		[_pressedButtons addObject: OFGameControllerButtonY];

	_ZLPressure = (float)state.Gamepad.bLeftTrigger / 255;
	_ZRPressure = (float)state.Gamepad.bRightTrigger / 255;

	if (_ZLPressure > 0)
		[_pressedButtons addObject: OFGameControllerButtonZL];
	if (_ZRPressure > 0)
		[_pressedButtons addObject: OFGameControllerButtonZR];

	_leftAnalogStickPosition = OFMakePoint(
	    (float)state.Gamepad.sThumbLX /
	    (state.Gamepad.sThumbLX < 0 ? -INT16_MIN : INT16_MAX),
	    -(float)state.Gamepad.sThumbLY /
	    (state.Gamepad.sThumbLY < 0 ? -INT16_MIN : INT16_MAX));
	_rightAnalogStickPosition = OFMakePoint(
	    (float)state.Gamepad.sThumbRX /
	    (state.Gamepad.sThumbRX < 0 ? -INT16_MIN : INT16_MAX),
	    -(float)state.Gamepad.sThumbRY /
	    (state.Gamepad.sThumbRY < 0 ? -INT16_MIN : INT16_MAX));
}

- (OFString *)name
{
	return @"XInput 1.3";
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	return [OFSet setWithObjects:
	    OFGameControllerButtonA, OFGameControllerButtonB,
	    OFGameControllerButtonX, OFGameControllerButtonY,
	    OFGameControllerButtonL, OFGameControllerButtonR,
	    OFGameControllerButtonZL, OFGameControllerButtonZR,
	    OFGameControllerButtonStart, OFGameControllerButtonSelect,
	    OFGameControllerButtonLeftStick, OFGameControllerButtonRightStick,
	    OFGameControllerButtonDPadLeft, OFGameControllerButtonDPadRight,
	    OFGameControllerButtonDPadUp, OFGameControllerButtonDPadDown, nil];
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	return [[_pressedButtons copy] autorelease];
}

- (bool)hasLeftAnalogStick
{
	return true;
}

- (bool)hasRightAnalogStick
{
	return true;
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	if (button == OFGameControllerButtonZL)
		return _ZLPressure;
	if (button == OFGameControllerButtonZR)
		return _ZRPressure;

	return ([self.pressedButtons containsObject: button] ? 1 : 0);
}

- (OFGameControllerButton)northButton
{
	return OFGameControllerButtonY;
}

- (OFGameControllerButton)southButton
{
	return OFGameControllerButtonA;
}

- (OFGameControllerButton)westButton
{
	return OFGameControllerButtonX;
}

- (OFGameControllerButton)eastButton
{
	return OFGameControllerButtonB;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
