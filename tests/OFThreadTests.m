/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *module = @"OFThread";

@interface TestThread: OFThread
@end

@implementation TestThread
- (id)main
{
	[[OFThread threadDictionary] setObject: @"bar"
					forKey: @"foo"];

	return @"success";
}
@end

@implementation TestsAppDelegate (OFThreadTests)
- (void)threadTests
{
	void *pool = objc_autoreleasePoolPush();
	TestThread *t;
	OFMutableDictionary *d;

	TEST(@"+[thread]", (t = [TestThread thread]))

	TEST(@"-[start]", R([t start]))

	TEST(@"-[join]", [[t join] isEqual: @"success"])

	TEST(@"-[threadDictionary]", (d = [OFThread threadDictionary]) &&
	    [d objectForKey: @"foo"] == nil)

	objc_autoreleasePoolPop(pool);
}
@end
