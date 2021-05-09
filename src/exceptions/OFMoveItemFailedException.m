/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFMoveItemFailedException.h"
#import "OFString.h"
#import "OFURL.h"

@implementation OFMoveItemFailedException
@synthesize sourceURL = _sourceURL, destinationURL = _destinationURL;
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSourceURL: (OFURL *)sourceURL
			destinationURL: (OFURL *)destinationURL
				 errNo: (int)errNo
{
	return [[[self alloc] initWithSourceURL: sourceURL
				 destinationURL: destinationURL
					  errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSourceURL: (OFURL *)sourceURL
		   destinationURL: (OFURL *)destinationURL
			    errNo: (int)errNo
{
	self = [super init];

	@try {
		_sourceURL = [sourceURL copy];
		_destinationURL = [destinationURL copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_sourceURL release];
	[_destinationURL release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to move item at %@ to %@: %@",
	    _sourceURL, _destinationURL, OFStrError(_errNo)];
}
@end
