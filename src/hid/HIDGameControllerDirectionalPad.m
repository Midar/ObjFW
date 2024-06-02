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

#import "HIDGameControllerDirectionalPad.h"
#import "HIDGameControllerEmulatedAxis.h"
#import "HIDGameControllerEmulatedButton.h"

@implementation HIDGameControllerDirectionalPad
@synthesize xAxis = _xAxis, yAxis = _yAxis;
@synthesize upButton = _upButton, downButton = _downButton;
@synthesize leftButton = _leftButton, rightButton = _rightButton;

- (instancetype)initWithName: (OFString *)name
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		       xAxis: (HIDGameControllerAxis *)xAxis
		       yAxis: (HIDGameControllerAxis *)yAxis
{
	self = [super initWithName: name];

	@try {
		_xAxis = [xAxis retain];
		_yAxis = [yAxis retain];

		_upButton = [[HIDGameControllerEmulatedButton alloc]
		    initWithAxis: _yAxis
			positive: false];
		_downButton = [[HIDGameControllerEmulatedButton alloc]
		    initWithAxis: _yAxis
			positive: true];
		_leftButton = [[HIDGameControllerEmulatedButton alloc]
		    initWithAxis: _xAxis
			positive: false];
		_rightButton = [[HIDGameControllerEmulatedButton alloc]
		    initWithAxis: _xAxis
			positive: true];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithName: (OFString *)name
		    upButton: (HIDGameControllerButton *)upButton
		  downButton: (HIDGameControllerButton *)downButton
		  leftButton: (HIDGameControllerButton *)leftButton
		 rightButton: (HIDGameControllerButton *)rightButton
{
	self = [super initWithName: name];

	@try {
		_upButton = [upButton retain];
		_downButton = [downButton retain];
		_leftButton = [leftButton retain];
		_rightButton = [rightButton retain];

		_xAxis = [[HIDGameControllerEmulatedAxis alloc]
		    initWithNegativeButton: _leftButton
			    positiveButton: _rightButton];
		_yAxis = [[HIDGameControllerEmulatedAxis alloc]
		    initWithNegativeButton: _upButton
			    positiveButton: _downButton];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_xAxis release];
	[_yAxis release];
	[_upButton release];
	[_downButton release];
	[_leftButton release];
	[_rightButton release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
