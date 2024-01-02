/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFGetCurrentDirectoryFailedException.h"
#import "OFString.h"

@implementation OFGetCurrentDirectoryFailedException
@synthesize errNo = _errNo;

+ (instancetype)exceptionWithErrNo: (int)errNo
{
	return [[[self alloc] initWithErrNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithErrNo: (int)errNo
{
	self = [super init];

	_errNo = errNo;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Getting the current directory path failed: %@",
	    OFStrError(_errNo)];
}
@end
