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

#include "config.h"

#import "OFXMLNode.h"
#import "OFString.h"

@implementation OFXMLNode
- (instancetype)of_init
{
	return [super init];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFString *)stringValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setStringValue: (OFString *)stringValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (long long)longLongValue
{
	return self.stringValue.longLongValue;
}

- (long long)longLongValueWithBase: (unsigned char)base
{
	return [self.stringValue longLongValueWithBase: base];
}

- (unsigned long long)unsignedLongLongValue
{
	return self.stringValue.unsignedLongLongValue;
}

- (unsigned long long)unsignedLongLongValueWithBase: (unsigned char)base
{
	return [self.stringValue unsignedLongLongValueWithBase: base];
}

- (float)floatValue
{
	return self.stringValue.floatValue;
}

- (double)doubleValue
{
	return self.stringValue.doubleValue;
}

- (OFString *)XMLString
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	return self.XMLString;
}

- (id)copy
{
	return [self retain];
}
@end
