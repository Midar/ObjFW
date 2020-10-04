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

@class OFKernelEventObserver;

/**
 * @class OFObserveFailedException \
 *	  OFObserveFailedException.h ObjFW/OFObserveFailedException.h
 *
 * @brief An exception indicating that observing failed.
 */
@interface OFObserveFailedException: OFException
{
	OFKernelEventObserver *_observer;
	int _errNo;
}

/**
 * @brief The observer which failed to observe.
 */
@property (readonly, nonatomic) OFKernelEventObserver *observer;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased observe failed exception
 */
+ (instancetype)exceptionWithObserver: (OFKernelEventObserver *)observer
				errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return An initialized observe failed exception
 */
- (instancetype)initWithObserver: (OFKernelEventObserver *)observer
			   errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
