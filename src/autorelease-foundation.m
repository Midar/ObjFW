/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

/*
 * This file provides a wrapper to use the Foundation implementation for
 * autorelease pools.
 *
 * If we're using the Apple runtime and it doesn't have autorelease pools, we
 * need to use the implementation from Foundation to make ObjFWBridge work. We
 * can't use the ObjFWRT implementation as that would result in two parallel
 * autorelease pool chains.
 */

#include "config.h"

#import <Foundation/Foundation.h>

void *
objc_autoreleasePoolPush(void)
{
	return [[NSAutoreleasePool alloc] init];
}

void
objc_autoreleasePoolPop(void *pool)
{
	return [(id)pool drain];
}

id
_objc_rootAutorelease(id object)
{
	[NSAutoreleasePool addObject: object];

	return object;
}
