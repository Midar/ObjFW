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

@class OFSandbox;

/**
 * @class OFSandboxActivationFailedException \
 *	  OFSandboxActivationFailedException.h \
 *	  ObjFW/OFSandboxActivationFailedException.h
 *
 * @brief An exception indicating that sandboxing the process failed.
 */
@interface OFSandboxActivationFailedException: OFException
{
	OFSandbox *_sandbox;
	int _errNo;
}

/**
 * @brief The sandbox which could not be activated.
 */
@property (readonly, nonatomic) OFSandbox *sandbox;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased sandboxing failed exception
 */
+ (instancetype)exceptionWithSandbox: (OFSandbox *)sandbox
			       errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return An initialized sandboxing failed exception
 */
- (instancetype)initWithSandbox: (OFSandbox *)sandbox
			  errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
