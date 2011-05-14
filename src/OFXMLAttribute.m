/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFXMLAttribute.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

@implementation OFXMLAttribute
+ attributeWithName: (OFString*)name
	  namespace: (OFString*)ns
	stringValue: (OFString*)value
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: value] autorelease];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns_
   stringValue: (OFString*)value
{
	self = [super init];

	@try {
		name = [name_ copy];
		ns = [ns_ copy];
		stringValue = [value copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[name release];
	[ns release];
	[stringValue release];

	[super dealloc];
}

- (OFString*)name
{
	return [[name copy] autorelease];
}

- (OFString*)namespace
{
	return [[ns copy] autorelease];
}

- (OFString*)stringValue
{
	return [[stringValue copy] autorelease];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool;
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"object"
				      namespace: OF_SERIALIZATION_NS];

	pool = [[OFAutoreleasePool alloc] init];

	[element addAttributeWithName: @"class"
			  stringValue: [self className]];

	[element addChild:
	    [OFXMLElement elementWithName: @"name"
				namespace: OF_SERIALIZATION_NS
			      stringValue: name]];
	if (ns != nil)
		[element addChild:
		    [OFXMLElement elementWithName: @"namespace"
					namespace: OF_SERIALIZATION_NS
				      stringValue: ns]];
	[element addChild:
	    [OFXMLElement elementWithName: @"stringValue"
				namespace: OF_SERIALIZATION_NS
			      stringValue: stringValue]];

	[pool release];

	return element;
}
@end
