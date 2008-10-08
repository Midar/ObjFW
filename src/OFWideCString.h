/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <wchar.h>
#import <stddef.h>

#import "OFString.h"

@interface OFWideCString: OFString
{
	wchar_t	*string;
}

- initWithWideCString: (wchar_t*)str;
- (wchar_t*)wcString;
- (OFString*)clone;
- (int)compareTo: (OFString*)str;
- (OFString*)append: (OFString*)str;
@end
