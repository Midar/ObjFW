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

#import "OHWiiClassicController.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"ZL", @"ZR", @"+", @"-", @"Home"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHWiiClassicController
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
		OHGameControllerButton *up, *down, *left, *right;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]
				  analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
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
		    initWithName: @"Left Thumbstick"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: true] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RX"
			  analog: true] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RY"
			  analog: true] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Right Thumbstick"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: true] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

		up = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Up"
			  analog: false] autorelease];
		down = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Down"
			  analog: false] autorelease];
		left = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Left"
			  analog: false] autorelease];
		right = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Right"
			  analog: false] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: up
			    down: down
			    left: left
			   right: right
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
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"ZL"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"ZR"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"L"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"R"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return nil;
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return nil;
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"+"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"-"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Home"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}
@end
