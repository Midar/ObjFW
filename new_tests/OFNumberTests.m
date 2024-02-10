/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFNumberTests: OTTestCase
@end

extern unsigned long OFHashSeed;

@implementation OFNumberTests
- (void)testIsEqual
{
	OFNumber *number = [OFNumber numberWithLongLong: 123456789];
	OTAssertEqualObjects(number, [OFNumber numberWithLong: 123456789]);
}

- (void)testHash
{
	unsigned long long hashSeed = OFHashSeed;
	OFHashSeed = 0;
	@try {
		OFNumber *number = [OFNumber numberWithLongLong: 123456789];
		OTAssertEqual(number.hash, 0x82D8BC42);
	} @finally {
		OFHashSeed = hashSeed;
	};
}

- (void)testCharValue
{
	OFNumber *number = [OFNumber numberWithLongLong: 123456789];
	OTAssertEqual(number.charValue, 21);
}

- (void)testDoubleValue
{
	OFNumber *number = [OFNumber numberWithLongLong: 123456789];
	OTAssertEqual(number.doubleValue, 123456789.L);
}

- (void)testSignedCharMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithChar: SCHAR_MIN] charValue],
	    SCHAR_MIN);
	OTAssertEqual([[OFNumber numberWithChar: SCHAR_MAX] charValue],
	    SCHAR_MAX);
}

- (void)testShortMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithShort: SHRT_MIN] shortValue],
	    SHRT_MIN);
	OTAssertEqual([[OFNumber numberWithShort: SHRT_MAX] shortValue],
	    SHRT_MAX);
}

- (void)testIntMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithInt: INT_MIN] intValue], INT_MIN);
	OTAssertEqual([[OFNumber numberWithInt: INT_MAX] intValue], INT_MAX);
}

- (void)testLongMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithLong: LONG_MIN] longValue],
	    LONG_MIN);
	OTAssertEqual([[OFNumber numberWithLong: LONG_MAX] longValue],
	    LONG_MAX);;
}

- (void)testLongLongMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithLongLong: LLONG_MIN] longLongValue],
	    LLONG_MIN);
	OTAssertEqual([[OFNumber numberWithLongLong: LLONG_MAX] longLongValue],
	    LLONG_MAX);
}

- (void)testUnsignedCharMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedChar: UCHAR_MAX]
	    unsignedCharValue], UCHAR_MAX);
}

- (void)testUnsignedShortMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedShort: USHRT_MAX]
	    unsignedShortValue], USHRT_MAX);
}

- (void)testUnsignedIntMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedInt: UINT_MAX]
	    unsignedIntValue], UINT_MAX);
}

- (void)testUnsignedLongMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedLong: ULONG_MAX]
	    unsignedLongValue], ULONG_MAX);
}

- (void)testUnsignedLongLongMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedLongLong: ULLONG_MAX]
	    unsignedLongLongValue], ULLONG_MAX);
}
@end
