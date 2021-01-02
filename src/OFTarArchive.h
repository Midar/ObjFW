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

#import "OFObject.h"
#import "OFKernelEventObserver.h"
#import "OFString.h"
#import "OFTarArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

/**
 * @class OFTarArchive OFTarArchive.h ObjFW/OFTarArchive.h
 *
 * @brief A class for accessing and manipulating tar archives.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFTarArchive: OFObject
{
	OFStream *_stream;
	enum {
		OF_TAR_ARCHIVE_MODE_READ,
		OF_TAR_ARCHIVE_MODE_WRITE,
		OF_TAR_ARCHIVE_MODE_APPEND
	} _mode;
	of_string_encoding_t _encoding;
	OFStream *_Nullable _lastReturnedStream;
}

/**
 * @brief The encoding to use for the archive. Defaults to UTF-8.
 */
@property (nonatomic) of_string_encoding_t encoding;

/**
 * @brief A stream for reading the current entry.
 *
 * @note This is only available in read mode.
 *
 * @note The returned stream conforms to @ref OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 */
@property (readonly, nonatomic) OFStream *streamForReadingCurrentEntry;

/**
 * @brief Creates a new OFTarArchive object with the specified stream.
 *
 * @param stream A stream from which the tar archive will be read.
 *		 For append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFTarArchive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream
			     mode: (OFString *)mode;

#ifdef OF_HAVE_FILES
/**
 * @brief Creates a new OFTarArchive object with the specified file.
 *
 * @param path The path to the tar archive
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFTarArchive
 */
+ (instancetype)archiveWithPath: (OFString *)path
			   mode: (OFString *)mode;
#endif

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the tar archive will be read.
 *		 For append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFTarArchive
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

#ifdef OF_HAVE_FILES
/**
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified file.
 *
 * @param path The path to the tar archive
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFTarArchive
 */
- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode;
#endif

/**
 * @brief Returns the next entry from the tar archive or `nil` if all entries
 *	  have been read.
 *
 * @note This is only available in read mode.
 *
 * @warning Calling @ref nextEntry will invalidate all streams returned by
 *	    @ref streamForReadingCurrentEntry or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @return The next entry from the tar archive or `nil` if all entries have
 *	   been read
 */
- (nullable OFTarArchiveEntry *)nextEntry;

/**
 * @brief Returns a stream for writing the specified entry.
 *
 * @note This is only available in write and append mode.
 *
 * @note The returned stream conforms to @ref OFReadyForWritingObserving if the
 *	 underlying stream does so, too.
 *
 * @warning Calling @ref nextEntry will invalidate all streams returned by
 *	    @ref streamForReadingCurrentEntry or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @param entry The entry for which a stream for writing should be returned
 * @return A stream for writing the specified entry
 */
- (OFStream *)streamForWritingEntry: (OFTarArchiveEntry *)entry;

/**
 * @brief Closes the OFTarArchive.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
