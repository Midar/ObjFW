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

#import "OFObject.h"
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @class OFMessagePackExtension \
 *	  OFMessagePackExtension.h ObjFW/OFMessagePackExtension.h
 *
 * @brief A class for representing the MessagePack extension type.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMessagePackExtension: OFObject <OFMessagePackRepresentation,
    OFCopying>
{
	int8_t _type;
	OFData *_data;
}

/**
 * @brief The MessagePack extension type.
 */
@property (readonly, nonatomic) int8_t type;

/**
 * @brief The data of the extension.
 */
@property (readonly, nonatomic) OFData *data;

/**
 * @brief Creates a new OFMessagePackRepresentation with the specified type and
 *	  data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return A new, autoreleased OFMessagePackRepresentation
 */
+ (instancetype)extensionWithType: (int8_t)type data: (OFData *)data;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMessagePackRepresentation with the
 *	  specified type and data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return An initialized OFMessagePackRepresentation
 */
- (instancetype)initWithType: (int8_t)type
			data: (OFData *)data OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
