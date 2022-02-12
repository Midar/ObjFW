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

#import "OFPair.h"
#import "OFString.h"

@implementation OFPair
+ (instancetype)pairWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
{
	return [[[self alloc] initWithFirstObject: firstObject
				     secondObject: secondObject] autorelease];
}

- (instancetype)initWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
{
	self = [super init];

	@try {
		_firstObject = [firstObject retain];
		_secondObject = [secondObject retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_firstObject release];
	[_secondObject release];

	[super dealloc];
}

- (id)firstObject
{
	return _firstObject;
}

- (id)secondObject
{
	return _secondObject;
}

- (bool)isEqual: (id)object
{
	OFPair *pair;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFPair class]])
		return false;

	pair = object;

	if (pair->_firstObject != _firstObject &&
	    ![pair->_firstObject isEqual: _firstObject])
		return false;

	if (pair->_secondObject != _secondObject &&
	    ![pair->_secondObject isEqual: _secondObject])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, [_firstObject hash]);
	OFHashAddHash(&hash, [_secondObject hash]);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutablePair alloc] initWithFirstObject: _firstObject
					     secondObject: _secondObject];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<<%@, %@>>",
					   _firstObject, _secondObject];
}
@end
