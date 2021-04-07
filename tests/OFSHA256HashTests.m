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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFSHA256Hash";

const uint8_t testfile_sha256[32] =
	"\x1A\x02\xD6\x46\xF5\xA6\xBA\xAA\xFF\x7F\xD5\x87\xBA\xC3\xF6\xC6\xB5"
	"\x67\x93\x8F\x0F\x44\x90\xB8\xF5\x35\x89\xF0\x5A\x23\x7F\x69";

@implementation TestsAppDelegate (SHA256HashTests)
- (void)SHA256HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA256Hash *sha256, *copy;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin" mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (sha256 = [OFSHA256Hash hashWithAllowsSwappableMemory: true]))

	while (!f.atEndOfStream) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf length: 64];
		[sha256 updateWithBuffer: buf length: len];
	}
	[f close];

	TEST(@"-[copy]", (copy = [[sha256 copy] autorelease]))

	TEST(@"-[digest]",
	    memcmp(sha256.digest, testfile_sha256, 32) == 0 &&
	    memcmp(copy.digest, testfile_sha256, 32) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [sha256 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
