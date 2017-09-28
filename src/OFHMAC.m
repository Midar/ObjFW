/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFHMAC.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFInvalidArgumentException.h"

@implementation OFHMAC
@synthesize hashClass = _hashClass;

+ (instancetype)HMACWithHashClass: (Class <OFCryptoHash>)class
{
	return [[[self alloc] initWithHashClass: class] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithHashClass: (Class <OFCryptoHash>)class
{
	self = [super init];

	_hashClass = class;

	return self;
}

- (void)dealloc
{
	[_outerHash release];
	[_innerHash release];
	[_outerHashCopy release];
	[_innerHashCopy release];

	[super dealloc];
}

- (void)setKey: (const void *)key
	length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	size_t blockSize = [_hashClass blockSize];
	uint8_t outerKeyPad[blockSize], innerKeyPad[blockSize];

	[_outerHash release];
	[_innerHash release];
	[_outerHashCopy release];
	[_innerHashCopy release];
	_outerHash = _innerHash = _outerHashCopy = _innerHashCopy = nil;

	if (length > blockSize) {
		id <OFCryptoHash> hash = [_hashClass cryptoHash];

		[hash updateWithBuffer: key
				length: length];

		length = [_hashClass digestSize];
		if OF_UNLIKELY (length > blockSize)
			length = blockSize;

		memcpy(outerKeyPad, [hash digest], length);
		memcpy(innerKeyPad, [hash digest], length);
	} else {
		memcpy(outerKeyPad, key, length);
		memcpy(innerKeyPad, key, length);
	}

	memset(outerKeyPad + length, 0, blockSize - length);
	memset(innerKeyPad + length, 0, blockSize - length);

	for (size_t i = 0; i < blockSize; i++) {
		outerKeyPad[i] ^= 0x5C;
		innerKeyPad[i] ^= 0x36;
	}

	_outerHash = [[_hashClass cryptoHash] retain];
	_innerHash = [[_hashClass cryptoHash] retain];

	[_outerHash updateWithBuffer: outerKeyPad
			      length: blockSize];
	[_innerHash updateWithBuffer: innerKeyPad
			      length: blockSize];

	objc_autoreleasePoolPop(pool);

	_outerHashCopy = [_outerHash copy];
	_innerHashCopy = [_innerHash copy];

	_calculated = false;
}

- (void)updateWithBuffer: (const void *)buffer
		  length: (size_t)length
{
	if (_innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	[_innerHash updateWithBuffer: buffer
			      length: length];
}

- (const unsigned char *)digest
{
	if (_outerHash == nil || _innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		return (const unsigned char *)[_outerHash digest];

	[_outerHash updateWithBuffer: (const unsigned char *)[_innerHash digest]
			      length: [_hashClass digestSize]];
	_calculated = true;

	return (const unsigned char *)[_outerHash digest];
}

- (size_t)digestSize
{
	return [_hashClass digestSize];
}

- (void)reset
{
	[_outerHash release];
	[_innerHash release];
	_outerHash = _innerHash = nil;

	_outerHash = [_outerHashCopy copy];
	_innerHash = [_innerHashCopy copy];

	_calculated = false;
}

- (void)zero
{
	[_outerHash release];
	[_innerHash release];
	[_outerHashCopy release];
	[_innerHashCopy release];
	_outerHash = _innerHash = _outerHashCopy = _innerHashCopy = nil;

	_calculated = false;
}
@end
