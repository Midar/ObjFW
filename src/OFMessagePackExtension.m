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

#import "OFMessagePackExtension.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFMessagePackExtension
@synthesize type = _type, data = _data;

+ (instancetype)extensionWithType: (int8_t)type data: (OFData *)data
{
	return [[[self alloc] initWithType: type data: data] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithType: (int8_t)type data: (OFData *)data
{
	self = [super init];

	@try {
		if (data == nil || data.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		_type = type;
		_data = [data copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *ret;
	uint8_t prefix;
	size_t count = _data.count;

	if (count == 1) {
		ret = [OFMutableData dataWithCapacity: 3];

		prefix = 0xD4;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 2) {
		ret = [OFMutableData dataWithCapacity: 4];

		prefix = 0xD5;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 4) {
		ret = [OFMutableData dataWithCapacity: 6];

		prefix = 0xD6;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 8) {
		ret = [OFMutableData dataWithCapacity: 10];

		prefix = 0xD7;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 16) {
		ret = [OFMutableData dataWithCapacity: 18];

		prefix = 0xD8;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count < 0x100) {
		uint8_t length;

		ret = [OFMutableData dataWithCapacity: count + 3];

		prefix = 0xC7;
		[ret addItem: &prefix];

		length = (uint8_t)count;
		[ret addItem: &length];

		[ret addItem: &_type];
	} else if (count < 0x10000) {
		uint16_t length;

		ret = [OFMutableData dataWithCapacity: count + 4];

		prefix = 0xC8;
		[ret addItem: &prefix];

		length = OFToBigEndian16((uint16_t)count);
		[ret addItems: &length count: 2];

		[ret addItem: &_type];
	} else {
		uint32_t length;

		ret = [OFMutableData dataWithCapacity: count + 6];

		prefix = 0xC9;
		[ret addItem: &prefix];

		length = OFToBigEndian32((uint32_t)count);
		[ret addItems: &length count: 4];

		[ret addItem: &_type];
	}

	[ret addItems: _data.items count: _data.count];
	[ret makeImmutable];

	return ret;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFMessagePackExtension: %d, %@>",
					   _type, _data];
}

- (bool)isEqual: (id)object
{
	OFMessagePackExtension *extension;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMessagePackExtension class]])
		return false;

	extension = object;

	if (extension->_type != _type || ![extension->_data isEqual: _data])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddByte(&hash, (uint8_t)_type);
	OFHashAddHash(&hash, _data.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}
@end
