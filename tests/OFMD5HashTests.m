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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFMD5Hash";

const uint8_t testfile_md5[16] =
	"\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";

@implementation TestsAppDelegate (OFMD5HashTests)
- (void)MD5HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMD5Hash *md5, *copy;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"r"];

	TEST(@"+[cryptoHash]", (md5 = [OFMD5Hash cryptoHash]))

	while (!f.atEndOfStream) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[md5 updateWithBuffer: buf
			       length: len];
	}
	[f close];

	TEST(@"-[copy]", (copy = [[md5 copy] autorelease]))

	TEST(@"-[digest]",
	    memcmp(md5.digest, testfile_md5, 16) == 0 &&
	    memcmp(copy.digest, testfile_md5, 16) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length]", OFHashAlreadyCalculatedException,
	    [md5 updateWithBuffer: ""
			   length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
