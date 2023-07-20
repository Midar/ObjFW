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

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFThread;

/**
 * @class OFStartThreadFailedException \
 *	  OFStartThreadFailedException.h ObjFW/OFStartThreadFailedException.h
 *
 * @brief An exception indicating that starting a thread failed.
 */
@interface OFStartThreadFailedException: OFException
{
	OFThread *_Nullable _thread;
	int _errNo;
	OF_RESERVE_IVARS(OFStartThreadFailedException, 4)
}

/**
 * @brief The thread which could not be started.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFThread *thread;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased thread start failed exception.
 *
 * @param thread The thread which could not be started
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased thread start failed exception
 */
+ (instancetype)exceptionWithThread: (nullable OFThread *)thread
			      errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated thread start failed exception.
 *
 * @param thread The thread which could not be started
 * @param errNo The errno of the error that occurred
 * @return An initialized thread start failed exception
 */
- (instancetype)initWithThread: (nullable OFThread *)thread
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
