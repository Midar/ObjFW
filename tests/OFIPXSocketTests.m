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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFIPXSocket";

@implementation TestsAppDelegate (OFIPXSocketTests)
- (void)IPXSocketTests
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
	void *pool = objc_autoreleasePoolPush();
	OFIPXSocket *sock;
	OFSocketAddress address1, address2;
	char buffer[5];
	unsigned char node1[IPX_NODE_LEN], node2[IPX_NODE_LEN];

	TEST(@"+[socket]", (sock = [OFIPXSocket socket]))

	@try {
		TEST(@"-[bindToNetwork:node:port:packetType:]",
		R(address1 = [sock bindToNetwork: 0
					    node: zeroNode
					    port: 0
				      packetType: 0]))
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFIPXSocket] -[bindToNetwork:node:port:"
			    @"packetType:]: IPX unsupported, skipping tests"];
			break;
		case EADDRNOTAVAIL:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFIPXSocket] -[bindToNetwork:node:port:"
			    @"packetType:]: IPX not configured, skipping "
			    @"tests"];
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
	    R(OFSocketAddressGetIPXNode(&address1, node1)) &&
	    R(OFSocketAddressGetIPXNode(&address2, node2)) &&
	    memcmp(node1, node2, IPX_NODE_LEN) == 0 &&
	    OFSocketAddressIPXPort(&address1) ==
	    OFSocketAddressIPXPort(&address2))

	objc_autoreleasePoolPop(pool);
}
@end
