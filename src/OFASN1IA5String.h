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

@class OFString;

/**
 * @brief An ASN.1 IA5String.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1IA5String: OFObject
{
	OFString *_IA5StringValue;
}

/**
 * @brief The IA5String value.
 */
@property (readonly, nonatomic) OFString *IA5StringValue;

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates an IA5String with the specified string value.
 *
 * @param stringValue The string value of the IA5String
 * @return A new, autoreleased OFASN1IA5String
 */
+ (instancetype)stringWithStringValue: (OFString *)stringValue;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated IA5String with the specified string
 *	  value.
 *
 * @param stringValue The string value of the IA5String
 * @return An initialized OFASN1IA5String
 */
- (instancetype)initWithStringValue: (OFString *)stringValue
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated ASN.1 IA5String with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized OFASN1IA5String
 */
- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents;
@end

OF_ASSUME_NONNULL_END
