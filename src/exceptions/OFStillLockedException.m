/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#import "OFStillLockedException.h"
#import "OFString.h"

@implementation OFStillLockedException
@synthesize lock = _lock;

+ (instancetype)exceptionWithLock: (id <OFLocking>)lock
{
	return [[[self alloc] initWithLock: lock] autorelease];
}

- (instancetype)init
{
	return [self initWithLock: nil];
}

- (instancetype)initWithLock: (id <OFLocking>)lock
{
	self = [super init];

	_lock = [lock retain];

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
		    @"Deallocation of a lock of type %@ even though it was "
		    @"still locked!", [_lock class]];
	else
		return @"Deallocation of a lock even though it was still "
		    @"locked!";
}
@end
