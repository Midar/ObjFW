/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFReadOrWriteFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFReadFailedException \
 *	  OFReadFailedException.h ObjFW/OFReadFailedException.h
 *
 * @brief An exception indicating that reading from an object failed.
 */
@interface OFReadFailedException: OFReadOrWriteFailedException
{
	OF_RESERVE_IVARS(OFReadFailedException, 4)
}
@end

OF_ASSUME_NONNULL_END
