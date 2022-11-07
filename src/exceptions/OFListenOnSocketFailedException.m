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

#import "OFListenOnSocketFailedException.h"
#import "OFString.h"

@implementation OFListenOnSocketFailedException
@synthesize socket = _socket, backlog = _backlog, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSocket: (id)sock
			    backlog: (int)backlog
			      errNo: (int)errNo
{
	return [[[self alloc] initWithSocket: sock
				     backlog: backlog
				       errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSocket: (id)sock backlog: (int)backlog errNo: (int)errNo
{
	self = [super init];

	_socket = [sock retain];
	_backlog = backlog;
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_socket release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to listen in socket of type %@ with a back log of %d: %@",
	    [_socket class], _backlog, OFStrError(_errNo)];
}
@end
