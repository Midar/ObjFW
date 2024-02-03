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

#import "OFInvertedCharacterSet.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFInvertedCharacterSet
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet
{
	self = [super init];

	@try {
		_characterSet = [characterSet retain];
		_characterIsMember = (bool (*)(id, SEL, OFUnichar))
		    [_characterSet methodForSelector:
		    @selector(characterIsMember:)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	return !_characterIsMember(_characterSet, @selector(characterIsMember:),
	    character);
}

- (OFCharacterSet *)invertedSet
{
	return [[_characterSet retain] autorelease];
}
@end
