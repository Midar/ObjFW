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

- (instancetype)initWithSerialization: (OFXMLElement *)element
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

- (long long)longLongValueWithBase: (int)base
{
	return [self.stringValue longLongValueWithBase: base];
}

- (unsigned long long)unsignedLongLongValue
{
	return self.stringValue.unsignedLongLongValue;
}

- (unsigned long long)unsignedLongLongValueWithBase: (int)base
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
	return [self XMLStringWithIndentation: 0
					level: 0];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self XMLStringWithIndentation: 0
					level: 0];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
				 level: (unsigned int)level
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	return [self XMLStringWithIndentation: 2];
}

- (OFXMLElement *)XMLElementBySerializing
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)copy
{
	return [self retain];
}
@end
