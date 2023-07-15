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

/**
 * @class OFUnknownXMLEntityException \
 *	  OFUnknownXMLEntityException.h ObjFW/OFUnknownXMLEntityException.h
 *
 * @brief An exception indicating that a parser encountered an unknown XML
 *	  entity.
 */
@interface OFUnknownXMLEntityException: OFException
{
	OFString *_entityName;
	OF_RESERVE_IVARS(OFUnknownXMLEntityException, 4)
}

/**
 * @brief The name of the unknown XML entity.
 */
@property (readonly, nonatomic) OFString *entityName;

/**
 * @brief Creates a new, autoreleased unknown XML entity exception.
 *
 * @param entityName The name of the unknown XML entity
 * @return A new, autoreleased unknown XML entity exception
 */
+ (instancetype)exceptionWithEntityName: (OFString *)entityName;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unknown XML entity exception.
 *
 * @param entityName The name of the unknown XML entity
 * @return An initialized unknown XML entity exception
 */
- (instancetype)initWithEntityName: (OFString *)entityName
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
