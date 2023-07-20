/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFDeleteWindowsRegistryKeyFailedException.h"

#import "OFData.h"

@implementation OFDeleteWindowsRegistryKeyFailedException
@synthesize registryKey = _registryKey, subkeyPath = _subkeyPath;
@synthesize status = _status;

+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      subkeyPath: (OFString *)subkeyPath
				  status: (LSTATUS)status
{
	return [[[self alloc] initWithRegistryKey: registryKey
				       subkeyPath: subkeyPath
					   status: status] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			 subkeyPath: (OFString *)subkeyPath
			     status: (LSTATUS)status
{
	self = [super init];

	@try {
		_registryKey = [registryKey retain];
		_subkeyPath = [subkeyPath copy];
		_status = status;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_registryKey release];
	[_subkeyPath release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to delete subkey at path %@: %@",
	    _subkeyPath, OFWindowsStatusToString(_status)];
}
@end
