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
#import "OFSerialization.h"
#import "OFMessagePackRepresentation.h"

/*! @file */

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFURL;

/**
 * @brief Options for searching in data.
 *
 * This is a bit mask.
 */
typedef enum {
	/** Search backwards in the data */
	OFDataSearchBackwards = 1
} OFDataSearchOptions;

/**
 * @class OFData OFData.h ObjFW/OFData.h
 *
 * @brief A class for storing arbitrary data in an array.
 *
 * For security reasons, serialization and deserialization is only implemented
 * for OFData with item size 1.
 */
@interface OFData: OFObject <OFCopying, OFMutableCopying, OFComparing,
    OFSerialization, OFMessagePackRepresentation>
{
	unsigned char *_items;
	size_t _count, _itemSize;
	bool _freeWhenDone;
@private
	OFData *_parentData;
	OF_RESERVE_IVARS(OFData, 4)
}

/**
 * @brief The size of a single item in the OFData in bytes.
 */
@property (readonly, nonatomic) size_t itemSize;

/**
 * @brief The number of items in the OFData.
 */
@property (readonly, nonatomic) size_t count;

/**
 * @brief All elements of the OFData as a C array.
 *
 * @warning The pointer is only valid until the OFData is changed!
 */
@property (readonly, nonatomic) const void *items OF_RETURNS_INNER_POINTER;

/**
 * @brief The first item of the OFData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) const void *firstItem
    OF_RETURNS_INNER_POINTER;

/**
 * @brief The last item of the OFData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) const void *lastItem
    OF_RETURNS_INNER_POINTER;

/**
 * @brief The string representation of the data.
 *
 * The string representation is a hex dump of the data, grouped by itemSize
 * bytes.
 */
@property (readonly, nonatomic) OFString *stringRepresentation;

/**
 * @brief A string containing the data in Base64 encoding.
 */
@property (readonly, nonatomic) OFString *stringByBase64Encoding;

/**
 * @brief Creates a new OFData with the specified `count` items of size 1.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItems: (const void *)items count: (size_t)count;

/**
 * @brief Creates a new OFData with the specified `count` items of the
 *	  specified size.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param itemSize The item size of a single item in bytes
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize;

/**
 * @brief Creates a new OFData with the specified `count` items of size 1 by
 *	  taking over ownership of the specified items pointer.
 *
 * If initialization fails for whatever reason, the passed memory is *not*
 * free'd if `freeWhenDone` is true.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone;

/**
 * @brief Creates a new OFData with the specified `count` items of the
 *	  specified size by taking ownership of the specified items pointer.
 *
 * If initialization fails for whatever reason, the passed memory is *not*
 * free'd if `freeWhenDone` is true.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param itemSize The item size of a single item in bytes
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone;

#ifdef OF_HAVE_FILES
/**
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the specified file.
 *
 * @param path The path of the file
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithContentsOfFile: (OFString *)path;
#endif

/**
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the specified URL.
 *
 * @param URL The URL to the contents for the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithContentsOfURL: (OFURL *)URL;

/**
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithStringRepresentation: (OFString *)string;

/**
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithBase64EncodedString: (OFString *)string;

/**
 * @brief Initialized an already allocated OFData with the specified `count`
 *	  items of size 1.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @return An initialized OFData
 */
- (instancetype)initWithItems: (const void *)items count: (size_t)count;

/**
 * @brief Initialized an already allocated OFData with the specified `count`
 *	  items of the specified size.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param itemSize The item size of a single item in bytes
 * @return An initialized OFData
 */
- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize;

/**
 * @brief Initializes an already allocated OFData with the specified `count`
 *	  items of size 1 by taking over ownership of the specified items
 *	  pointer.
 *
 * If initialization fails for whatever reason, the passed memory is *not*
 * free'd if `freeWhenDone` is true.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return An initialized OFData
 */
- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone;

/**
 * @brief Initializes an already allocated OFData with the specified `count`
 *	  items of the specified size by taking ownership of the specified
 *	  items pointer.
 *
 * If initialization fails for whatever reason, the passed memory is *not*
 * free'd if `freeWhenDone` is true.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param itemSize The item size of a single item in bytes
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return An initialized OFData
 */
- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone;

#ifdef OF_HAVE_FILES
/**
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the specified file.
 *
 * @param path The path of the file
 * @return An initialized OFData
 */
- (instancetype)initWithContentsOfFile: (OFString *)path;
#endif

/**
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the specified URL.
 *
 * @param URL The URL to the contents for the OFData
 * @return A new autoreleased OFData
 */
- (instancetype)initWithContentsOfURL: (OFURL *)URL;

/**
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFData
 */
- (instancetype)initWithStringRepresentation: (OFString *)string;

/**
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return An initialized OFData
 */
- (instancetype)initWithBase64EncodedString: (OFString *)string;

/**
 * @brief Compares the data to other data.
 *
 * @param data Data to compare the data to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (OFData *)data;

/**
 * @brief Returns a specific item of the OFData.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFData
 */
- (const void *)itemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/**
 * @brief Returns the data in the specified range as a new OFData.
 *
 * @param range The range of the data for the new OFData
 * @return The data in the specified range as a new OFData
 */
- (OFData *)subdataWithRange: (OFRange)range;

/**
 * @brief Returns the range of the data.
 *
 * @param data The data to search for
 * @param options Options modifying search behavior
 * @param range The range in which to search
 * @return The range of the first occurrence of the data or a range with
 *	   `OFNotFound` as start position if it was not found.
 */
- (OFRange)rangeOfData: (OFData *)data
	       options: (OFDataSearchOptions)options
		 range: (OFRange)range;

#ifdef OF_HAVE_FILES
/**
 * @brief Writes the OFData into the specified file.
 *
 * @param path The path of the file to write to
 */
- (void)writeToFile: (OFString *)path;
#endif

/**
 * @brief Writes the OFData to the specified URL.
 *
 * @param URL The URL to write to
 */
- (void)writeToURL: (OFURL *)URL;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableData.h"
#import "OFData+CryptographicHashing.h"
#import "OFData+MessagePackParsing.h"
