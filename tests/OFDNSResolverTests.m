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

static OFString *module = @"OFDNSResolverTests";

@implementation TestsAppDelegate (OFDNSResolverTests)
- (void)DNSResolverTests
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSResolver *resolver = [OFDNSResolver resolver];
	OFMutableString *staticHosts = [OFMutableString string];

	for (OFString *host in resolver.staticHosts) {
		OFString *IPs;

		if (staticHosts.length > 0)
			[staticHosts appendString: @"; "];

		IPs = [[resolver.staticHosts objectForKey: host]
		    componentsJoinedByString: @", "];

		[staticHosts appendFormat: @"%@=(%@)", host, IPs];
	}
	PRINT(GREEN, @"Static hosts: %@", staticHosts);

	PRINT(GREEN, @"Name servers: %@",
	    [resolver.nameServers componentsJoinedByString: @", "]);

	PRINT(GREEN, @"Local domain: %@", resolver.localDomain);

	PRINT(GREEN, @"Search domains: %@",
	    [resolver.searchDomains componentsJoinedByString: @", "]);

	PRINT(GREEN, @"Timeout: %lf", resolver.timeout);

	PRINT(GREEN, @"Max attempts: %u", resolver.maxAttempts);

	PRINT(GREEN, @"Min number of dots in absolute name: %u",
	    resolver.minNumberOfDotsInAbsoluteName);

	PRINT(GREEN, @"Uses TCP: %u", resolver.usesTCP);

	PRINT(GREEN, @"Config reload interval: %lf",
	    resolver.configReloadInterval);

	objc_autoreleasePoolPop(pool);
}
@end
