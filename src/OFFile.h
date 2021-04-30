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

#import "OFSeekableStream.h"
#import "OFKernelEventObserver.h"

#ifndef OF_AMIGAOS
# define OF_FILE_HANDLE_IS_FD
typedef int OFFileHandle;
static const OFFileHandle OFInvalidFileHandle = -1;
#else
typedef struct _OFFileHandle *OFFileHandle;
static const OFFileHandle OFInvalidFileHandle = NULL;
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFURL;

/**
 * @class OFFile OFFile.h ObjFW/OFFile.h
 *
 * @brief A class which provides methods to read and write files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFFile: OFSeekableStream
#ifdef OF_FILE_HANDLE_IS_FD
    <OFReadyForReadingObserving, OFReadyForWritingObserving>
#endif
{
	OFFileHandle _handle;
	bool _atEndOfStream;
}

/**
 * @brief Creates a new OFFile with the specified path and mode.
 *
 * @param path The path to the file to open as a string
 * @param mode The mode in which the file should be opened.
 *             @n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithPath: (OFString *)path mode: (OFString *)mode;

/**
 * @brief Creates a new OFFile with the specified URL and mode.
 *
 * @param URL The URL to the file to open
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithURL: (OFURL *)URL mode: (OFString *)mode;

/**
 * @brief Creates a new OFFile with the specified native file handle.
 *
 * @param handle A native file handle. If OF_FILE_HANDLE_IS_FD is defined, this
 *		 is a file descriptor. The handle is closed when the OFFile
 *		 object is deallocated!
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithHandle: (OFFileHandle)handle;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFFile.
 *
 * @param path The path to the file to open as a string
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | read-only
 *	       `rb`           | read-only, binary
 *	       `r+`           | read-write
 *	       `rb+` or `r+b` | read-write, binary
 *	       `w`            | write-only, create, truncate
 *	       `wb`           | write-only, create, truncate, binary
 *	       `w`            | read-write, create, truncate
 *	       `wb+` or `w+b` | read-write, create, truncate, binary
 *	       `a`            | write-only, create, append
 *	       `ab`           | write-only, create, append, binary
 *	       `a+`           | read-write, create, append
 *	       `ab+` or `a+b` | read-write, create, append, binary
 * @return An initialized OFFile
 */
- (instancetype)initWithPath: (OFString *)path mode: (OFString *)mode;

/**
 * @brief Initializes an already allocated OFFile.
 *
 * @param URL The URL to the file to open
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | read-only
 *	       `rb`           | read-only, binary
 *	       `r+`           | read-write
 *	       `rb+` or `r+b` | read-write, binary
 *	       `w`            | write-only, create, truncate
 *	       `wb`           | write-only, create, truncate, binary
 *	       `w`            | read-write, create, truncate
 *	       `wb+` or `w+b` | read-write, create, truncate, binary
 *	       `a`            | write-only, create, append
 *	       `ab`           | write-only, create, append, binary
 *	       `a+`           | read-write, create, append
 *	       `ab+` or `a+b` | read-write, create, append, binary
 * @return An initialized OFFile
 */
- (instancetype)initWithURL: (OFURL *)URL mode: (OFString *)mode;

/**
 * @brief Initializes an already allocated OFFile.
 *
 * @param handle A native file handle. If OF_FILE_HANDLE_IS_FD is defined, this
 *		 is a file descriptor. The handle is closed when the OFFile
 *		 object is deallocated!
 * @return An initialized OFFile
 */
- (instancetype)initWithHandle: (OFFileHandle)handle OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
