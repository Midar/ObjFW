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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLCharacters OFXMLCharacters.h ObjFW/OFXMLCharacters.h
 *
 * @brief A class representing XML characters.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFXMLCharacters: OFXMLNode
{
	OFString *_characters;
}

/**
 * @brief Creates a new OFXMLCharacters with the specified string.
 *
 * @param string The string value for the characters
 * @return A new OFXMLCharacters
 */
+ (instancetype)charactersWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated OFXMLCharacters with the specified
 *	  string.
 *
 * @param string The string value for the characters
 * @return An initialized OFXMLCharacters
 */
- (instancetype)initWithString: (OFString *)string;
@end

OF_ASSUME_NONNULL_END
