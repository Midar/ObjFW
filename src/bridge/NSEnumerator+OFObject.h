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

#import <Foundation/NSEnumerator.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFEnumerator OF_GENERIC(ObjectType);

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSEnumerator_OFObject_reference;
#ifdef __cplusplus
}
#endif

/**
 * @category NSEnumerator (OFObject) \
 *	     NSEnumerator+OFObject.h ObjFWBridge/NSEnumerator+OFObject.h
 *
 * @brief Support for bridging NSEnumerators to OFEnumerators.
 */
@interface NSEnumerator (OFObject) <NSBridging>
@property (readonly, nonatomic) OFEnumerator *OFObject;
@end

OF_ASSUME_NONNULL_END
