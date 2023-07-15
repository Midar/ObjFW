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

#import "OFLHAArchive.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFLHAArchiveEntry ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
- (instancetype)of_initWithHeader: (char [_Nonnull 21])header
			   stream: (OFStream *)stream
			 encoding: (OFStringEncoding)encoding
    OF_METHOD_FAMILY(init) OF_DIRECT;
- (void)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding OF_DIRECT;
@end

OF_ASSUME_NONNULL_END
