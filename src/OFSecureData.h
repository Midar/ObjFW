/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSecureData OFSecureData.h ObjFW/OFSecureData.h
 *
 * @brief A class for storing arbitrary data in secure memory, securely wiping
 *	  it when it gets deallocated.
 *
 * @note Secure memory might be unavailable on the platform, in which case this
 *	 falls back to insecure (potentially swappable) memory.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFSecureData: OFData
{
	struct page *_page;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic, getter=isSecure) bool secure;
#endif

/*!
 * @brief All items of the OFSecureData as a C array.
 *
 * Modifying the returned array directly is allowed and will change the contents
 * of the data.
 */
@property (readonly, nonatomic) void *mutableItems OF_RETURNS_INNER_POINTER;

/*!
 * @brief Whether OFSecureData is secure, meaning preventing the data from
 *	  being swapped out is supported.
 */
+ (bool)isSecure;

/*!
 * @brief Preallocates the specified number of bytes.
 *
 * This is useful to allocate secure memory before enabling a sandbox that does
 * not allow it anymore.
 *
 * @note This may only be called once per thread!
 * @note Preallocated memory is only available for OFSecureData that is smaller
 *	 than a single page!
 *
 * @param size The number of bytes to preallocate
 */
+ (void)preallocateMemoryWithSize: (size_t)size;

/*!
 * @brief Creates a new, autoreleased OFSecureData with count items of item
 *	  size 1, all set to zero.
 *
 * @param count The number of zero items the OFSecureData should contain
 * @return A new, autoreleased OFSecureData
 */
+ (instancetype)dataWithCount: (size_t)count;

/*!
 * @brief Creates a new, autoreleased OFSecureData with count items of the
 *	  specified item size, all set to zero.
 *
 * @param itemSize The size of a single item in the OFSecureData in bytes
 * @param count The number of zero items the OFSecureData should contain
 * @return A new, autoreleased OFSecureData
 */
+ (instancetype)dataWithItemSize: (size_t)itemSize
			   count: (size_t)count;

#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path OF_UNAVAILABLE;
#endif
+ (instancetype)dataWithContentsOfURL: (OFURL *)URL OF_UNAVAILABLE;
+ (instancetype)dataWithStringRepresentation: (OFString *)string OF_UNAVAILABLE;
+ (instancetype)dataWithBase64EncodedString: (OFString *)string OF_UNAVAILABLE;
+ (instancetype)dataWithSerialization: (OFXMLElement *)element OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFSecureData with count items of
 *	  item size 1, all set to zero.
 *
 * @param count The number of zero items the OFSecureData should contain
 * @return An initialized OFSecureData
 */
- (instancetype)initWithCount: (size_t)count;

/*!
 * @brief Initializes an already allocated OFSecureData with count items of the
 *	  specified item size, all set to zero.
 *
 * @param itemSize The size of a single item in the OFSecureData in bytes
 * @param count The number of zero items the OFSecureData should contain
 * @return An initialized OFSecureData
 */
- (instancetype)initWithItemSize: (size_t)itemSize
			   count: (size_t)count;

/*!
 * @brief Returns a specific item of the OFSecureData.
 *
 * Modifying the returned item directly is allowed and will change the contents
 * of the data array.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFSecureData
 */
- (void *)mutableItemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/*!
 * @brief Checks the OFSecureData for equality to another object.
 *
 * If the specified object is a subclass of @ref OFData, the comparison is
 * performed in constant time.
 *
 * @param object The object which should be tested for equality
 * @return A boolean whether the OFSecureData is equal to the specified object
 */
- (bool)isEqual: (nullable id)object;

/*!
 * @brief Zeroes the data.
 */
- (void)zero;

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path OF_UNAVAILABLE;
#endif
- (instancetype)initWithContentsOfURL: (OFURL *)URL OF_UNAVAILABLE;
- (instancetype)initWithStringRepresentation: (OFString *)string OF_UNAVAILABLE;
- (instancetype)initWithBase64EncodedString: (OFString *)string OF_UNAVAILABLE;
- (instancetype)initWithSerialization: (OFXMLElement *)element OF_UNAVAILABLE;
- (OFString *)stringRepresentation OF_UNAVAILABLE;
- (OFString *)stringByBase64Encoding OF_UNAVAILABLE;
#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path OF_UNAVAILABLE;
#endif
- (void)writeToURL: (OFURL *)URL OF_UNAVAILABLE;
- (OFXMLElement *)XMLElementBySerializing OF_UNAVAILABLE;
- (OFData *)messagePackRepresentation OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
