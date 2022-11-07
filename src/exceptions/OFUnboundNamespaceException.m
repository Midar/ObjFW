/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFUnboundNamespaceException.h"
#import "OFString.h"
#import "OFXMLElement.h"

@implementation OFUnboundNamespaceException
@synthesize namespace = _namespace, element = _element;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithNamespace: (OFString *)namespace
			       element: (OFXMLElement *)element
{
	return [[[self alloc] initWithNamespace: namespace
					element: element] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithNamespace: (OFString *)namespace
			  element: (OFXMLElement *)element
{
	self = [super init];

	@try {
		_namespace = [namespace copy];
		_element = [element retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_namespace release];
	[_element release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The namespace %@ is not bound in an element of type %@!",
	    _namespace, _element.class];
}
@end
