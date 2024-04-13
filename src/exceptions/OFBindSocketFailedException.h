/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindSocketFailedException \
 *	  OFBindSocketFailedException.h ObjFW/OFBindSocketFailedException.h
 *
 * @brief An exception indicating that binding a socket failed.
 */
@interface OFBindSocketFailedException: OFException
{
	id _socket;
	int _errNo;
	OF_RESERVE_IVARS(OFBindSocketFailedException, 4)
}

/**
 * @brief The socket which could not be bound.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased bind socket failed exception.
 *
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind socket failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind socket failed exception.
 *
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind socket failed exception
 */
- (instancetype)initWithSocket: (id)socket
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
