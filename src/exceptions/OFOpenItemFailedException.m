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

#import "OFOpenItemFailedException.h"
#import "OFString.h"
#import "OFURI.h"

@implementation OFOpenItemFailedException
@synthesize URI = _URI, path = _path, mode = _mode, errNo = _errNo;

+ (instancetype)exceptionWithURI: (OFURI *)URI
			    mode: (OFString *)mode
			   errNo: (int)errNo
{
	return [[[self alloc] initWithURI: URI
				     mode: mode
				    errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (OFString *)mode
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				      mode: mode
				     errNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithURI: (OFURI *)URI
		       mode: (OFString *)mode
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_URI = [URI copy];
		_mode = [mode copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		_path = [path copy];
		_mode = [mode copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_URI release];
	[_path release];
	[_mode release];

	[super dealloc];
}

- (OFString *)description
{
	id item = nil;

	if (_URI != nil)
		item = _URI;
	else if (_path != nil)
		item = _path;

	if (_mode != nil)
		return [OFString stringWithFormat:
		    @"Failed to open file %@ with mode %@: %@",
		    item, _mode, OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to open item %@: %@", item, OFStrError(_errNo)];
}
@end
