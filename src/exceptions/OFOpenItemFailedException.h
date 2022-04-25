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

@class OFURL;

/**
 * @class OFOpenItemFailedException \
 *	  OFOpenItemFailedException.h ObjFW/OFOpenItemFailedException.h
 *
 * @brief An exception indicating an item could not be opened.
 */
@interface OFOpenItemFailedException: OFException
{
	OFURL *_Nullable _URL;
	OFString *_Nullable _path;
	OFString *_mode;
	int _errNo;
}

/**
 * @brief The URL of the item which could not be opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFURL *URL;

/**
 * @brief The path of the item which could not be opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief The mode in which the item should have been opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *mode;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param URL The URL of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithURL: (OFURL *)URL
			    mode: (nullable OFString *)mode
			   errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path The path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (nullable OFString *)mode
			    errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param URL The URL of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- (instancetype)initWithURL: (OFURL *)URL
		       mode: (nullable OFString *)mode
		      errNo: (int)errNo;

/**
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path The path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- (instancetype)initWithPath: (OFString *)path
			mode: (nullable OFString *)mode
		       errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
