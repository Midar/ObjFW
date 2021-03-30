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

#import "NSOFDictionary.h"

#import "OFDictionary+NSObject.h"

int _OFDictionary_NSObject_reference;

@implementation OFDictionary (NSObject)
- (NSDictionary *)NSObject
{
	return [[[NSOFDictionary alloc]
	    initWithOFDictionary: self] autorelease];
}
@end
