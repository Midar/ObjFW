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

#include <string.h>

#import "OFUnlockFailedException.h"
#import "OFString.h"

@implementation OFUnlockFailedException
@synthesize lock = _lock, errNo = _errNo;

+ (instancetype)exceptionWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	return [[[self alloc] initWithLock: lock errNo: errNo] autorelease];
}

- (instancetype)initWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	self = [super init];

	_lock = [lock retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_lock release];

	[super dealloc];
}

- (OFString *)description
{
	if (_lock != nil)
		return [OFString stringWithFormat:
		    @"A lock of type %@ could not be unlocked: %s",
		    [_lock class], strerror(_errNo)];
	else
		return @"A lock could not be unlocked!";
}
@end
