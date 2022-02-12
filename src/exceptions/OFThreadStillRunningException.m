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

#import "OFThreadStillRunningException.h"
#import "OFString.h"
#import "OFThread.h"

@implementation OFThreadStillRunningException
@synthesize thread = _thread;

+ (instancetype)exceptionWithThread: (OFThread *)thread
{
	return [[[self alloc] initWithThread: thread] autorelease];
}

- (instancetype)init
{
	return [self initWithThread: nil];
}

- (instancetype)initWithThread: (OFThread *)thread
{
	self = [super init];

	_thread = [thread retain];

	return self;
}

- (void)dealloc
{
	[_thread release];

	[super dealloc];
}

- (OFString *)description
{
	if (_thread)
		return [OFString stringWithFormat:
		    @"Deallocation of a thread of type %@ was tried, even "
		    @"though it was still running!",
		    _thread.class];
	else
		return @"Deallocation of a thread was tried, even though it "
		    @"was still running!";
}
@end
