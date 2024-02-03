/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFSubdata.h"

@implementation OFSubdata
- (instancetype)initWithData: (OFData *)data range: (OFRange)range
{
	self = [super init];

	@try {
		/* Should usually be retain, as it's useless with a copy */
		_data = [data copy];
		_range = range;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (size_t)count
{
	return _range.length;
}

- (size_t)itemSize
{
	return _data.itemSize;
}

- (const void *)items
{
	return (const unsigned char *)_data.items +
	    (_range.location * _data.itemSize);
}
@end
