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

#import "OFUnboundPrefixException.h"
#import "OFString.h"
#import "OFXMLParser.h"

@implementation OFUnboundPrefixException
@synthesize prefix = _prefix, parser = _parser;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPrefix: (OFString *)prefix
			     parser: (OFXMLParser *)parser
{
	return [[[self alloc] initWithPrefix: prefix
				      parser: parser] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPrefix: (OFString *)prefix parser: (OFXMLParser *)parser
{
	self = [super init];

	@try {
		_prefix = [prefix copy];
		_parser = [parser retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_prefix release];
	[_parser release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"An XML parser of type %@ encountered the unbound prefix %@ in "
	    @"line %zu!", _parser.class, _prefix, _parser.lineNumber];
}
@end
