/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFSandboxActivationFailedException.h"
#import "OFString.h"
#import "OFSandbox.h"

@implementation OFSandboxActivationFailedException
@synthesize sandbox = _sandbox, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSandbox: (OFSandbox *)sandbox
			       errNo: (int)errNo
{
	return [[[self alloc] initWithSandbox: sandbox
					errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSandbox: (OFSandbox *)sandbox
			  errNo: (int)errNo
{
	self = [super init];

	_sandbox = [sandbox retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_sandbox release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The sandbox could not be applied: %@", of_strerror(_errNo)];
}
@end
