/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "plugin/TestPlugin.h"

#ifndef OF_IOS
# define PLUGIN_PATH @"plugin/TestPlugin"
#else
# define PLUGIN_PATH @"PlugIns/TestPlugin"
#endif

static OFString *module = @"OFPlugin";

@implementation TestsAppDelegate (OFPluginTests)
- (void)pluginTests
{
	void *pool = objc_autoreleasePoolPush();
	TestPlugin *plugin;

	TEST(@"+[pluginFromFile:]",
	    (plugin = [OFPlugin pluginFromFile: PLUGIN_PATH]))

	TEST(@"TestPlugin's -[test:]", [plugin test: 1234] == 2468)

	objc_autoreleasePoolPop(pool);
}
@end
