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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFUnsupportedVersionException \
 *	  OFUnsupportedVersionException.h ObjFW/OFUnsupportedVersionException.h
 *
 * @brief An exception indicating that the specified version of the format or
 *	  protocol is not supported.
 */
@interface OFUnsupportedVersionException: OFException
{
	OFString *_version;
}

/**
 * @brief The version which is unsupported.
 */
@property (readonly, nonatomic) OFString *version;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased unsupported version exception.
 *
 * @param version The version which is unsupported
 * @return A new, autoreleased unsupported version exception
 */
+ (instancetype)exceptionWithVersion: (OFString *)version;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unsupported protocol exception.
 *
 * @param version The version which is unsupported
 * @return An initialized unsupported version exception
 */
- (instancetype)initWithVersion: (OFString *)version OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
