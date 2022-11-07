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

#include <errno.h>
#include <string.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFSCTPSocket";

@implementation TestsAppDelegate (OFSCTPSocketTests)
- (void)SCTPSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSCTPSocket *server, *client = nil, *accepted;
	uint16_t port;
	char buf[6];

	TEST(@"+[socket]", (server = [OFSCTPSocket socket]) &&
	    (client = [OFSCTPSocket socket]))

	@try {
		TEST(@"-[bindToHost:port:]",
		    (port = [server bindToHost: @"127.0.0.1" port: 0]))
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EPROTONOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSCTPSocket] -[bindToHost:port:]: "
			    @"SCTP unsupported, skipping tests"];
			break;
		default:
			@throw e;
		}

		objc_autoreleasePoolPop(pool);
		return;
	}

	TEST(@"-[listen]", R([server listen]))

	TEST(@"-[connectToHost:port:]",
	    R([client connectToHost: @"127.0.0.1" port: port]))

	TEST(@"-[accept]", (accepted = [server accept]))

	TEST(@"-[remoteAddress]",
	    [OFSocketAddressString(accepted.remoteAddress)
	    isEqual: @"127.0.0.1"])

	TEST(@"-[sendBuffer:length:]",
	    R([client sendBuffer: "Hello!" length: 6]))

	TEST(@"-[receiveIntoBuffer:length:]",
	    [accepted receiveIntoBuffer: buf length: 6] &&
	    !memcmp(buf, "Hello!", 6))

	objc_autoreleasePoolPop(pool);
}
@end
