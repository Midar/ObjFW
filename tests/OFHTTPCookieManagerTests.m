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

#import "TestsAppDelegate.h"

static OFString *module = @"OFHTTPCookieManager";

@implementation TestsAppDelegate (OFHTTPCookieManagerTests)
- (void)HTTPCookieManagerTests
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPCookieManager *manager = [OFHTTPCookieManager manager];
	OFURL *URL[4];
	OFHTTPCookie *cookie[5];

	URL[0] = [OFURL URLWithString: @"http://nil.im/foo"];
	URL[1] = [OFURL URLWithString: @"https://nil.im/foo/bar"];
	URL[2] = [OFURL URLWithString: @"https://test.nil.im/foo/bar"];
	URL[3] = [OFURL URLWithString: @"http://webkeks.org/foo/bar"];

	cookie[0] = [OFHTTPCookie cookieWithName: @"test"
					   value: @"1"
					  domain: @"nil.im"];
	TEST(@"-[addCookie:forURL:] #1", R([manager addCookie: cookie[0]
						       forURL: URL[0]]))

	TEST(@"-[cookiesForURL:] #1",
	    [[manager cookiesForURL: URL[0]] isEqual:
	    [OFArray arrayWithObject: cookie[0]]])

	cookie[1] = [OFHTTPCookie cookieWithName: @"test"
					   value: @"2"
					  domain: @"webkeks.org"];
	TEST(@"-[addCookie:forURL:] #2", R([manager addCookie: cookie[1]
						       forURL: URL[0]]))

	TEST(@"-[cookiesForURL:] #2",
	    [[manager cookiesForURL: URL[0]] isEqual:
	    [OFArray arrayWithObject: cookie[0]]] &&
	    [[manager cookiesForURL: URL[3]] isEqual: [OFArray array]])

	cookie[2] = [OFHTTPCookie cookieWithName: @"test"
					   value: @"3"
					  domain: @"nil.im"];
	cookie[2].secure = true;
	TEST(@"-[addCookie:forURL:] #3", R([manager addCookie: cookie[2]
						       forURL: URL[1]]))

	TEST(@"-[cookiesForURL:] #3",
	    [[manager cookiesForURL: URL[1]] isEqual:
	    [OFArray arrayWithObject: cookie[2]]] &&
	    [[manager cookiesForURL: URL[0]] isEqual: [OFArray array]])

	cookie[2].expires = [OFDate dateWithTimeIntervalSinceNow: -1];
	cookie[3] = [OFHTTPCookie cookieWithName: @"test"
					   value: @"4"
					  domain: @"nil.im"];
	cookie[3].domain = @".nil.im";
	TEST(@"-[addCookie:forURL:] #4", R([manager addCookie: cookie[3]
						       forURL: URL[1]]))

	TEST(@"-[cookiesForURL:] #4",
	    [[manager cookiesForURL: URL[1]] isEqual:
	    [OFArray arrayWithObject: cookie[3]]] &&
	    [[manager cookiesForURL: URL[2]] isEqual:
	    [OFArray arrayWithObject: cookie[3]]])

	cookie[4] = [OFHTTPCookie cookieWithName: @"bar"
					   value: @"5"
					  domain: @"test.nil.im"];
	TEST(@"-[addCookie:forURL:] #5", R([manager addCookie: cookie[4]
						       forURL: URL[0]]))

	TEST(@"-[cookiesForURL:] #5",
	    [[manager cookiesForURL: URL[0]] isEqual:
	    [OFArray arrayWithObject: cookie[3]]] &&
	    [[manager cookiesForURL: URL[2]] isEqual:
	    [OFArray arrayWithObjects: cookie[3], cookie[4], nil]])

	TEST(@"-[purgeExpiredCookies]",
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie[2], cookie[3], cookie[4], nil]] &&
	    R([manager purgeExpiredCookies]) &&
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie[3], cookie[4], nil]])

	objc_autoreleasePoolPop(pool);
}
@end
