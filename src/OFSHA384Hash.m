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

#import "OFSHA384Hash.h"

#define DIGEST_SIZE 48

@implementation OFSHA384Hash
+ (size_t)digestSize
{
	return DIGEST_SIZE;
}

- (size_t)digestSize
{
	return DIGEST_SIZE;
}

- (void)of_resetState
{
	_iVars->state[0] = 0xCBBB9D5DC1059ED8;
	_iVars->state[1] = 0x629A292A367CD507;
	_iVars->state[2] = 0x9159015A3070DD17;
	_iVars->state[3] = 0x152FECD8F70E5939;
	_iVars->state[4] = 0x67332667FFC00B31;
	_iVars->state[5] = 0x8EB44A8768581511;
	_iVars->state[6] = 0xDB0C2E0D64F98FA7;
	_iVars->state[7] = 0x47B5481DBEFA4FA4;
}
@end
