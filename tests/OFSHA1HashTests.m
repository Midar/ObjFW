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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFSHA1Hash";

const uint8_t testfile_sha1[20] =
	"\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96\xF5"
	"\x94\xE7\x17";

@implementation TestsAppDelegate (SHA1HashTests)
- (void)SHA1HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA1Hash *sha1, *copy;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"r"];

	TEST(@"+[cryptoHashWithAllowsSwappableMemory:]",
	    (sha1 = [OFSHA1Hash cryptoHashWithAllowsSwappableMemory: true]))

	while (!f.atEndOfStream) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[sha1 updateWithBuffer: buf
				length: len];
	}
	[f close];

	TEST(@"-[copy]", (copy = [[sha1 copy] autorelease]))

	TEST(@"-[digest]",
	    memcmp(sha1.digest, testfile_sha1, 20) == 0 &&
	    memcmp(copy.digest, testfile_sha1, 20) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [sha1 updateWithBuffer: ""
			    length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
