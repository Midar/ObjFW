/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

/*!
 * @class OFGetCurrentDirectoryPathFailedException \
 *	  OFGetCurrentDirectoryPathFailedException.h \
 *	  ObjFW/OFGetCurrentDirectoryPathFailedException.h
 *
 * @brief An exception indicating that getting the current directory path
 *	  failed.
 */
@interface OFGetCurrentDirectoryPathFailedException: OFException
{
	int _errNo;
}

/*!
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased get current directory path failed
 *	  exception.
 *
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased get current directory failed exception
 */
+ (instancetype)exceptionWithErrNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated get current directory path failed
 *	  exception.
 *
 * @param errNo The errno of the error that occurred
 * @return An initialized get current directory path failed exception
 */
- (instancetype)initWithErrNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
