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

#import "OFHMAC.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFInvalidArgumentException.h"

@implementation OFHMAC
@synthesize hashClass = _hashClass;
@synthesize allowsSwappableMemory = _allowsSwappableMemory;

+ (instancetype)HMACWithHashClass: (Class <OFCryptographicHash>)class
	    allowsSwappableMemory: (bool)allowsSwappableMemory
{
	return [[[self alloc] initWithHashClass: class
			  allowsSwappableMemory: allowsSwappableMemory]
	    autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithHashClass: (Class <OFCryptographicHash>)class
	    allowsSwappableMemory: (bool)allowsSwappableMemory
{
	self = [super init];

	_hashClass = class;
	_allowsSwappableMemory = allowsSwappableMemory;

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

- (void)setKey: (const void *)key length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	size_t blockSize = [_hashClass blockSize];
	OFSecureData *outerKeyPad = [OFSecureData
		    dataWithCount: blockSize
	    allowsSwappableMemory: _allowsSwappableMemory];
	OFSecureData *innerKeyPad = [OFSecureData
		    dataWithCount: blockSize
	    allowsSwappableMemory: _allowsSwappableMemory];
	unsigned char *outerKeyPadItems = outerKeyPad.mutableItems;
	unsigned char *innerKeyPadItems = innerKeyPad.mutableItems;

	[_outerHash release];
	[_innerHash release];
	[_outerHashCopy release];
	[_innerHashCopy release];
	_outerHash = _innerHash = _outerHashCopy = _innerHashCopy = nil;

	@try {
		if (length > blockSize) {
			id <OFCryptographicHash> hash = [_hashClass
			    hashWithAllowsSwappableMemory:
			    _allowsSwappableMemory];
			[hash updateWithBuffer: key length: length];

			length = hash.digestSize;
			if OF_UNLIKELY (length > blockSize)
				length = blockSize;

			memcpy(outerKeyPadItems, hash.digest, length);
			memcpy(innerKeyPadItems, hash.digest, length);
		} else {
			memcpy(outerKeyPadItems, key, length);
			memcpy(innerKeyPadItems, key, length);
		}

		memset(outerKeyPadItems + length, 0, blockSize - length);
		memset(innerKeyPadItems + length, 0, blockSize - length);

		for (size_t i = 0; i < blockSize; i++) {
			outerKeyPadItems[i] ^= 0x5C;
			innerKeyPadItems[i] ^= 0x36;
		}

		_outerHash = [[_hashClass hashWithAllowsSwappableMemory:
		    _allowsSwappableMemory] retain];
		_innerHash = [[_hashClass hashWithAllowsSwappableMemory:
		    _allowsSwappableMemory] retain];

		[_outerHash updateWithBuffer: outerKeyPadItems
				      length: blockSize];
		[_innerHash updateWithBuffer: innerKeyPadItems
				      length: blockSize];
	} @catch (id e) {
		[outerKeyPad zero];
		[innerKeyPad zero];

		@throw e;
	}

	objc_autoreleasePoolPop(pool);

	_outerHashCopy = [_outerHash copy];
	_innerHashCopy = [_innerHash copy];

	_calculated = false;
}

- (void)updateWithBuffer: (const void *)buffer length: (size_t)length
{
	if (_innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	[_innerHash updateWithBuffer: buffer length: length];
}

- (const unsigned char *)digest
{
	if (_outerHash == nil || _innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		return _outerHash.digest;

	[_outerHash updateWithBuffer: _innerHash.digest
			      length: _innerHash.digestSize];
	_calculated = true;

	return _outerHash.digest;
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
