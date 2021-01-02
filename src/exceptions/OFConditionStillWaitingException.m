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

#import "OFConditionStillWaitingException.h"
#import "OFString.h"
#import "OFCondition.h"

@implementation OFConditionStillWaitingException
@synthesize condition = _condition;

+ (instancetype)exceptionWithCondition: (OFCondition *)condition
{
	return [[[self alloc] initWithCondition: condition] autorelease];
}

- (instancetype)init
{
	return [self initWithCondition: nil];
}

- (instancetype)initWithCondition: (OFCondition *)condition
{
	self = [super init];

	_condition = [condition retain];

	return self;
}

- (void)dealloc
{
	[_condition release];

	[super dealloc];
}

- (OFString *)description
{
	if (_condition != nil)
		return [OFString stringWithFormat:
		    @"Deallocation of a condition of type %@ was tried, even "
		    "though a thread was still waiting for it!",
		    _condition.class];
	else
		return @"Deallocation of a condition was tried, even though a "
		    "thread was still waiting for it!";
}
@end
