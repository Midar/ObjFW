/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import <Foundation/NSDictionary.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDictionary OF_GENERIC(KeyType, ObjectType);

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSDictionary_OFObject_reference OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

/**
 * @category NSDictionary (OFObject) \
 *	     NSDictionary+OFObject.h ObjFWBridge/NSDictionary+OFObject.h
 *
 * @brief Support for bridging NSDictionaries to OFDictionaries.
 */
@interface NSDictionary (OFObject) <NSBridging>
@property (readonly, nonatomic) OFDictionary *OFObject;
@end

OF_ASSUME_NONNULL_END
