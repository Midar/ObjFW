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

#import "OFEnumerator.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFCollection OFCollection.h ObjFW/OFCollection.h
 *
 * @brief A protocol with methods common for all collections.
 */
@protocol OFCollection <OFEnumeration, OFFastEnumeration>
/**
 * @brief The number of objects in the collection
 */
@property (readonly, nonatomic) size_t count;

/**
 * @brief Checks whether the collection contains an object equal to the
 *	  specified object.
 *
 * @param object The object which is checked for being in the collection
 * @return A boolean whether the collection contains the specified object
 */
- (bool)containsObject: (id)object;
@end

OF_ASSUME_NONNULL_END
