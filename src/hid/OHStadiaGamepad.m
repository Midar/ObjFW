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

#import "OHStadiaGamepad.h"
#import "OHStadiaGamepad+Private.h"
#import "OFDictionary.h"
#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L1", @"R1", @"L3", @"R3", @"Menu", @"Options",
	@"Capture", @"Stadia", @"Assistant"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHStadiaGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OHGameControllerButton *button;
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *axis, *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			button = [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]
				  analog: false] autorelease];
			[buttons setObject: button forKey: buttonNames[i]];
		}

		axis = [[[OHGameControllerAxis alloc]
		    initWithName: @"L2"
			  analog: true] autorelease];
		button = [[[OHEmulatedGameControllerTriggerButton alloc]
		    initWithName: @"L2"
			    axis: axis] autorelease];
		[buttons setObject: button forKey: @"L2"];

		axis = [[[OHGameControllerAxis alloc]
		    initWithName: @"R2"
			  analog: true] autorelease];
		button = [[[OHEmulatedGameControllerTriggerButton alloc]
		    initWithName: @"R2"
			    axis: axis] autorelease];
		[buttons setObject: button forKey: @"R2"];

		[buttons makeImmutable];
		_buttons = [buttons retain];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"X"
			  analog: true] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"Y"
			  analog: true] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Left Stick"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: true] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Stick"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RX"
			  analog: true] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RY"
			  analog: true] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Right Stick"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: true] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Stick"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"D-Pad X"
			  analog: false] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"D-Pad Y"
			  analog: false] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: false] autorelease];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_buttons release];
	[_directionalPads release];

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

- (OHGameControllerButton *)northButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"L1"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"R1"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"L2"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"R2"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"L3"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"R3"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Menu"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Options"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Stadia"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Left Stick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"Right Stick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	switch (button) {
	case BTN_A:
		name = @"A";
		break;
	case BTN_B:
		name = @"B";
		break;
	case BTN_X:
		name = @"X";
		break;
	case BTN_Y:
		name = @"Y";
		break;
	case BTN_TL:
		name = @"L1";
		break;
	case BTN_TR:
		name = @"R1";
		break;
	case BTN_THUMBL:
		name = @"L3";
		break;
	case BTN_THUMBR:
		name = @"R3";
		break;
	case BTN_START:
		name = @"Menu";
		break;
	case BTN_SELECT:
		name = @"Options";
		break;
	case BTN_MODE:
		name = @"Stadia";
		break;
	case BTN_TRIGGER_HAPPY1:
		name = @"Assistant";
		break;
	case BTN_TRIGGER_HAPPY2:
		name = @"Capture";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Left Stick"] xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Stick"] yAxis];
	case ABS_Z:
		return [[_directionalPads objectForKey: @"Right Stick"] xAxis];
	case ABS_RZ:
		return [[_directionalPads objectForKey: @"Right Stick"] yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	case ABS_BRAKE:
		return ((OHEmulatedGameControllerTriggerButton *)
		    [_buttons objectForKey: @"L2"]).axis;
	case ABS_GAS:
		return ((OHEmulatedGameControllerTriggerButton *)
		    [_buttons objectForKey: @"R2"]).axis;
	default:
		return nil;
	}
}
#endif
@end
