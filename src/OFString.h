/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

/**
 * A class for storing and modifying strings.
 */
@interface OFString: OFObject
{
	char   *string;
	size_t length;
	BOOL   is_utf8;
}

/**
 * Creates a new OFString.
 *
 * \return An initialized OFString
 */
+ new;

/**
 * Creates a new OFString from a C string.
 *
 * \param str A C string to initialize the OFString with
 * \return A new OFString
 */
+ newFromCString: (const char*)str;

/**
 * Initializes an already allocated OFString.
 *
 * \return An initialized OFString
 */
- init;

/**
 * Initializes an already allocated OFString from a C string.
 *
 * \param str A C string to initialize the OFString with
 * \return An initialized OFString
 */
- initFromCString: (const char*)str;

/**
 * \return The OFString as a wide C string
 */
- (const char*)cString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * Clones the OFString, creating a new one.
 *
 * \return A copy of the OFString
 */
- (OFString*)clone;

/**
 * Frees the OFString and sets it to the specified OFString.
 *
 * \param str An OFString to set the OFString to.
 * \return The new OFString
 */
- (OFString*)setTo: (OFString*)str;

/**
 * Compares the OFString to another OFString.
 *
 * \param str An OFString to compare with
 * \return An integer which is the result of the comparison, see wcscmp
 */
- (int)compareTo: (OFString*)str;

/**
 * Append another OFString to the OFString.
 *
 * \param str An OFString to append
 */
- append: (OFString*)str;

/**
 * Append a C string to the OFString.
 *
 * \param str A C string to append
 */
- appendCString: (const char*)str;

/**
 * Reverse the OFString.
 */
- reverse;

/**
 * Upper the OFString.
 */
- upper;

/**
 * Lower the OFString.
 */
- lower;
@end
