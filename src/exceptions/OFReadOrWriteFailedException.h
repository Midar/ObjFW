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
 * @class OFReadOrWriteFailedException \
 *	  OFReadOrWriteFailedException.h ObjFW/OFReadOrWriteFailedException.h
 *
 * @brief An exception indicating that reading from or writing to an object
 *	  failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	id _object;
	size_t _requestedLength;
	int _errNo;
	OF_RESERVE_IVARS(OFReadOrWriteFailedException, 4)
}

/**
 * @brief The stream which caused the read or write failed exception.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief The requested length of the data that could not be read / written.
 */
@property (readonly, nonatomic) size_t requestedLength;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased read or write failed exception
 */
+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
			      errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param errNo The errno of the error that occurred
 * @return A new open file failed exception
 */
- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
