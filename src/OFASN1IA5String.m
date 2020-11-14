/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFASN1IA5String.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1IA5String
@synthesize IA5StringValue = _IA5StringValue;

+ (instancetype)stringWithStringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithStringValue: stringValue] autorelease];
}

- (instancetype)initWithStringValue: (OFString *)stringValue
{
	self = [super init];

	@try {
		_IA5StringValue = [stringValue copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFString *IA5StringValue;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_IA5_STRING || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		IA5StringValue = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OF_STRING_ENCODING_ASCII
			       length: DEREncodedContents.count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithStringValue: IA5StringValue];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_IA5StringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return self.IA5StringValue;
}

- (bool)isEqual: (id)object
{
	OFASN1IA5String *IA5String;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1IA5String class]])
		return false;

	IA5String = object;

	if (![IA5String->_IA5StringValue isEqual: _IA5StringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _IA5StringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1IA5String: %@>",
					   _IA5StringValue];
}
@end
