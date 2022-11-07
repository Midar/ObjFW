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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFHTTPCookieManager";

@implementation TestsAppDelegate (OFHTTPCookieManagerTests)
- (void)HTTPCookieManagerTests
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPCookieManager *manager = [OFHTTPCookieManager manager];
	OFURI *URI1, *URI2, *URI3, *URI4;
	OFHTTPCookie *cookie1, *cookie2, *cookie3, *cookie4, *cookie5;

	URI1 = [OFURI URIWithString: @"http://nil.im/foo"];
	URI2 = [OFURI URIWithString: @"https://nil.im/foo/bar"];
	URI3 = [OFURI URIWithString: @"https://test.nil.im/foo/bar"];
	URI4 = [OFURI URIWithString: @"http://webkeks.org/foo/bar"];

	cookie1 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"1"
					domain: @"nil.im"];
	TEST(@"-[addCookie:forURI:] #1",
	    R([manager addCookie: cookie1 forURI: URI1]))

	TEST(@"-[cookiesForURI:] #1",
	    [[manager cookiesForURI: URI1] isEqual:
	    [OFArray arrayWithObject: cookie1]])

	cookie2 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"2"
					domain: @"webkeks.org"];
	TEST(@"-[addCookie:forURI:] #2",
	    R([manager addCookie: cookie2 forURI: URI1]))

	TEST(@"-[cookiesForURI:] #2",
	    [[manager cookiesForURI: URI1] isEqual:
	    [OFArray arrayWithObject: cookie1]] &&
	    [[manager cookiesForURI: URI4] isEqual: [OFArray array]])

	cookie3 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"3"
					domain: @"nil.im"];
	cookie3.secure = true;
	TEST(@"-[addCookie:forURI:] #3",
	    R([manager addCookie: cookie3 forURI: URI2]))

	TEST(@"-[cookiesForURI:] #3",
	    [[manager cookiesForURI: URI2] isEqual:
	    [OFArray arrayWithObject: cookie3]] &&
	    [[manager cookiesForURI: URI1] isEqual: [OFArray array]])

	cookie3.expires = [OFDate dateWithTimeIntervalSinceNow: -1];
	cookie4 = [OFHTTPCookie cookieWithName: @"test"
					 value: @"4"
					domain: @"nil.im"];
	cookie4.domain = @".nil.im";
	TEST(@"-[addCookie:forURI:] #4",
	    R([manager addCookie: cookie4 forURI: URI2]))

	TEST(@"-[cookiesForURI:] #4",
	    [[manager cookiesForURI: URI2] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForURI: URI3] isEqual:
	    [OFArray arrayWithObject: cookie4]])

	cookie5 = [OFHTTPCookie cookieWithName: @"bar"
					 value: @"5"
					domain: @"test.nil.im"];
	TEST(@"-[addCookie:forURI:] #5",
	    R([manager addCookie: cookie5 forURI: URI1]))

	TEST(@"-[cookiesForURI:] #5",
	    [[manager cookiesForURI: URI1] isEqual:
	    [OFArray arrayWithObject: cookie4]] &&
	    [[manager cookiesForURI: URI3] isEqual:
	    [OFArray arrayWithObjects: cookie4, cookie5, nil]])

	TEST(@"-[purgeExpiredCookies]",
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie3, cookie4, cookie5, nil]] &&
	    R([manager purgeExpiredCookies]) &&
	    [manager.cookies isEqual:
	    [OFArray arrayWithObjects: cookie4, cookie5, nil]])

	objc_autoreleasePoolPop(pool);
}
@end
