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

#import <stdlib.h>
#import <string.h>

#import "OFString.h"
#import "OFConstCString.h"
#import "OFConstWideCString.h"
#import "OFCString.h"
#import "OFWideCString.h"
#import "OFExceptions.h"

@implementation OFString
+ newWithConstCString: (const char*)str
{
	return [[OFConstCString alloc] initWithConstCString: str];
}

+ newWithConstWideCString: (const wchar_t*)str
{
	return [[OFConstWideCString alloc] initWithConstWideCString: str];
}

+ newWithCString: (char*)str
{
	return [[OFCString alloc] initWithCString: str];
}

+ newWithWideCString: (wchar_t*)str
{
	return [[OFWideCString alloc] initWithWideCString: str];
}

- (char*)cString
{
	[[OFNotImplementedException newWithObject: self
				      andSelector: @selector(cString)] raise];
	return NULL;
}

- (wchar_t*)wcString
{
	[[OFNotImplementedException newWithObject: self
				      andSelector: @selector(wcString)] raise];
	return NULL;
}

- (size_t)length
{
	return length;
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	self = [str clone];
	return self;
}

- (OFString*)clone
{
	[[OFNotImplementedException newWithObject: self
				      andSelector: @selector(clone)] raise];
	return nil;
}

- (int)compareTo: (OFString*)str
{
	[[OFNotImplementedException newWithObject: self
				      andSelector: @selector(compareTo:)]
	    raise];
	return 0;
}

- (OFString*)append: (OFString*)str
{
	[[OFNotImplementedException newWithObject: self
				      andSelector: @selector(append:)] raise];
	return nil;
}
@end
