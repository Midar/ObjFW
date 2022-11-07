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

#import "OFASN1Value.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Value
@synthesize tagClass = _tagClass, tagNumber = _tagNumber;
@synthesize constructed = _constructed;
@synthesize DEREncodedContents = _DEREncodedContents;

+ (instancetype)valueWithTagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber
		      constructed: (bool)constructed
	       DEREncodedContents: (OFData *)DEREncodedContents
{
	return [[[self alloc]
	      initWithTagClass: tagClass
		     tagNumber: tagNumber
		   constructed: constructed
	    DEREncodedContents: DEREncodedContents] autorelease];
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidFormatException exception];

		_tagClass = tagClass;
		_tagNumber = tagNumber;
		_constructed = constructed;
		_DEREncodedContents = [DEREncodedContents copy];
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
	[_DEREncodedContents release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1Value *value;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	value = object;

	if (value->_tagClass != _tagClass)
		return false;
	if (value->_tagNumber != _tagNumber)
		return false;
	if (value->_constructed != _constructed)
		return false;
	if (![value->_DEREncodedContents isEqual: _DEREncodedContents])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddByte(&hash, _tagClass & 0xFF);
	OFHashAddByte(&hash, _tagNumber & 0xFF);
	OFHashAddByte(&hash, _constructed);
	OFHashAddHash(&hash, _DEREncodedContents.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1Value:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tConstructed = %u\n"
	    @"\tDER-encoded contents = %@\n"
	    @">",
	    _tagClass, _tagNumber, _constructed,
	    _DEREncodedContents.description];
}
@end
