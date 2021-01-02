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

#import "OFObject.h"
#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief An ASN.1 Enumerated.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Enumerated: OFObject
{
	long long _longLongValue;
}

/**
 * @brief The integer value.
 */
@property (readonly, nonatomic) long long longLongValue;

/**
 * @brief Creates an ASN.1 Enumerated with the specified integer value.
 *
 * @param value The `long long` value of the Enumerated
 * @return A new, autoreleased OFASN1Enumerated
 */
+ (instancetype)enumeratedWithLongLong: (long long)value;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 Enumerated with the specified
 *	  integer value.
 *
 * @param value The `long long` value of the Enumerated
 * @return An initialized OFASN1Enumerated
 */
- (instancetype)initWithLongLong: (long long)value OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated ASN.1 Enumerated with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized OFASN1Enumerated
 */
- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents;
@end

OF_ASSUME_NONNULL_END
