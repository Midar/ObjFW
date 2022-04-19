/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
 * @class OFMemoryNotPartOfObjectException \
 *	  OFMemoryNotPartOfObjectException.h \
 *	  ObjFW/OFMemoryNotPartOfObjectException.h
 *
 * @brief An exception indicating the given memory is not part of the object.
 */
@interface OFMemoryNotPartOfObjectException: OFException
{
	void *_Nullable _pointer;
	id _object;
}

/**
 * @brief A pointer to the memory which is not part of the object.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *pointer;

/**
 * @brief The object which the memory is not part of.
 */
@property (readonly, nonatomic) id object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased memory not part of object exception.
 *
 * @param pointer A pointer to the memory that is not part of the object
 * @param object The object which the memory is not part of
 * @return A new, autoreleased memory not part of object exception
 */
+ (instancetype)exceptionWithPointer: (nullable void *)pointer
			      object: (id)object;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated memory not part of object exception.
 *
 * @param pointer A pointer to the memory that is not part of the object
 * @param object The object which the memory is not part of
 * @return An initialized memory not part of object exception
 */
- (instancetype)initWithPointer: (nullable void *)pointer
			 object: (id)object OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
