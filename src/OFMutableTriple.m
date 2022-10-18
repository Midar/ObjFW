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

#import "OFMutableTriple.h"

@implementation OFMutableTriple
@dynamic firstObject, secondObject, thirdObject;

- (void)setFirstObject: (id)firstObject
{
	id old = _firstObject;
	_firstObject = [firstObject retain];
	[old release];
}

- (void)setSecondObject: (id)secondObject
{
	id old = _secondObject;
	_secondObject = [secondObject retain];
	[old release];
}

- (void)setThirdObject: (id)thirdObject
{
	id old = _thirdObject;
	_thirdObject = [thirdObject retain];
	[old release];
}

- (id)copy
{
	OFMutableTriple *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)makeImmutable
{
	object_setClass(self, [OFTriple class]);
}
@end
