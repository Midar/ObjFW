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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;

/**
 * @class OFRemoveItemFailedException \
 *	  OFRemoveItemFailedException.h ObjFW/OFRemoveItemFailedException.h
 *
 * @brief An exception indicating that removing an item failed.
 */
@interface OFRemoveItemFailedException: OFException
{
	OFIRI *_IRI;
	int _errNo;
	OF_RESERVE_IVARS(OFRemoveItemFailedException, 4)
}

/**
 * @brief The IRI of the item which could not be removed.
 */
@property (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased remove failed exception.
 *
 * @param IRI The IRI of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased remove item failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated remove failed exception.
 *
 * @param IRI The IRI of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return An initialized remove item failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
