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

#include <errno.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFIPXSocket";

@implementation TestsAppDelegate (OFIPXSocketTests)
- (void)IPXSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFIPXSocket *sock;
	of_socket_address_t address1, address2;
	char buffer[5];

	TEST(@"+[socket]", (sock = [OFIPXSocket socket]))

	@try {
		TEST(@"-[bindToPort:packetType:]",
		    R(address1 = [sock bindToPort: 0 packetType: 0]))
	} @catch (OFBindFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			[of_stdout setForegroundColor: [OFColor lime]];
			[of_stdout writeLine:
			    @"\r[OFIPXSocket] -[bindToPort:packetType:]: "
			    @"IPX unsupported, skipping tests"];
			break;
		case EADDRNOTAVAIL:
			[of_stdout setForegroundColor: [OFColor lime]];
			[of_stdout writeLine:
			    @"\r[OFIPXSocket] -[bindToPort:packetType:]: "
			    @"IPX not configured, skipping tests"];
			break;
		default:
			@throw e;
		}

		objc_autoreleasePoolPop(pool);
		return;
	}

	TEST(@"-[sendBuffer:length:receiver:]",
	    R([sock sendBuffer: "Hello" length: 5 receiver: &address1]))

	TEST(@"-[receiveIntoBuffer:length:sender:]",
	    [sock receiveIntoBuffer: buffer length: 5 sender: &address2] == 5 &&
	    memcmp(buffer, "Hello", 5) == 0 &&
	    of_socket_address_equal(&address1, &address2) &&
	    of_socket_address_hash(&address1) ==
	    of_socket_address_hash(&address2))

	objc_autoreleasePoolPop(pool);
}
@end
