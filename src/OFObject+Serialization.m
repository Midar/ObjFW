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

#include <stdlib.h>

#import "OFObject.h"
#import "OFObject+Serialization.h"
#import "OFSerialization.h"
#import "OFString.h"
#import "OFXMLElement.h"

int _OFObject_Serialization_reference;

@implementation OFObject (Serialization)
- (OFString *)stringBySerializing
{
	void *pool;
	OFXMLElement *element;
	OFXMLElement *root;
	OFString *ret;

	if (![self conformsToProtocol: @protocol(OFSerialization)]) {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	pool = objc_autoreleasePoolPush();
	element = ((id <OFSerialization>)self).XMLElementBySerializing;

	root = [OFXMLElement elementWithName: @"serialization"
				   namespace: OF_SERIALIZATION_NS];
	[root addAttributeWithName: @"version" stringValue: @"1"];
	[root addChild: element];

	ret = [@"<?xml version='1.0' encoding='UTF-8'?>\n"
	    stringByAppendingString: [root XMLStringWithIndentation: 2]];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
