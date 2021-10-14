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

#import "OF4x4Matrix.h"
#import "OFString.h"

static const float identityValues[16] = {
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1
};
static OF4x4Matrix *identity;

@implementation OF4x4Matrix
+ (void)initialize
{
	if (self != [OF4x4Matrix class])
		return;

	identity = [[OF4x4Matrix alloc] initWithValues: identityValues];
}

+ (OF4x4Matrix *)identity
{
	return identity;
}

+ (instancetype)matrixWithValues: (const float [16])values
{
	return [[[self alloc] initWithValues: values] autorelease];
}

- (instancetype)initWithValues: (const float [16])values
{
	self = [super init];

	memcpy(_values, values, 16 * sizeof(float));

	return self;
}

- (float *)values
{
	return _values;
}

- (instancetype)copy
{
	return [[OF4x4Matrix alloc] initWithValues: _values];
}

- (bool)isEqual: (OF4x4Matrix *)matrix
{
	if (![matrix isKindOfClass: [OF4x4Matrix class]])
		return false;

	return (memcmp(_values, matrix->_values, 16 * sizeof(float)) == 0);
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < 16; i++)
		OFHashAddHash(&hash, OFFloatToRawUInt32(_values[i]));

	OFHashFinalize(&hash);

	return hash;
}

- (void)transpose
{
	float copy[16];
	memcpy(copy, _values, 16 * sizeof(float));

	_values[1] = copy[4];
	_values[2] = copy[8];
	_values[3] = copy[12];
	_values[4] = copy[1];
	_values[6] = copy[9];
	_values[7] = copy[13];
	_values[8] = copy[2];
	_values[9] = copy[6];
	_values[11] = copy[14];
	_values[12] = copy[3];
	_values[13] = copy[7];
	_values[14] = copy[11];
}

- (void)multiplyWithMatrix: (OF4x4Matrix *)matrix
{
	float copy[16];
	memcpy(copy, _values, 16 * sizeof(float));

	_values[0] = matrix->_values[0] * copy[0] +
	    matrix->_values[4] * copy[1] +
	    matrix->_values[8] * copy[2] +
	    matrix->_values[12] * copy[3];
	_values[1] = matrix->_values[1] * copy[0] +
	    matrix->_values[5] * copy[1] +
	    matrix->_values[9] * copy[2] +
	    matrix->_values[13] * copy[3];
	_values[2] = matrix->_values[2] * copy[0] +
	    matrix->_values[6] * copy[1] +
	    matrix->_values[10] * copy[2] +
	    matrix->_values[14] * copy[3];
	_values[3] = matrix->_values[3] * copy[0] +
	    matrix->_values[7] * copy[1] +
	    matrix->_values[11] * copy[2] +
	    matrix->_values[15] * copy[3];
	_values[4] = matrix->_values[0] * copy[4] +
	    matrix->_values[4] * copy[5] +
	    matrix->_values[8] * copy[6] +
	    matrix->_values[12] * copy[7];
	_values[5] = matrix->_values[1] * copy[4] +
	    matrix->_values[5] * copy[5] +
	    matrix->_values[9] * copy[6] +
	    matrix->_values[13] * copy[7];
	_values[6] = matrix->_values[2] * copy[4] +
	    matrix->_values[6] * copy[5] +
	    matrix->_values[10] * copy[6] +
	    matrix->_values[14] * copy[7];
	_values[7] = matrix->_values[3] * copy[4] +
	    matrix->_values[7] * copy[5] +
	    matrix->_values[11] * copy[6] +
	    matrix->_values[15] * copy[7];
	_values[8] = matrix->_values[0] * copy[8] +
	    matrix->_values[4] * copy[9] +
	    matrix->_values[8] * copy[10] +
	    matrix->_values[12] * copy[11];
	_values[9] = matrix->_values[1] * copy[8] +
	    matrix->_values[5] * copy[9] +
	    matrix->_values[9] * copy[10] +
	    matrix->_values[13] * copy[11];
	_values[10] = matrix->_values[2] * copy[8] +
	    matrix->_values[6] * copy[9] +
	    matrix->_values[10] * copy[10] +
	    matrix->_values[14] * copy[11];
	_values[11] = matrix->_values[3] * copy[8] +
	    matrix->_values[7] * copy[9] +
	    matrix->_values[11] * copy[10] +
	    matrix->_values[15] * copy[11];
	_values[12] = matrix->_values[0] * copy[12] +
	    matrix->_values[4] * copy[13] +
	    matrix->_values[8] * copy[14] +
	    matrix->_values[12] * copy[15];
	_values[13] = matrix->_values[1] * copy[12] +
	    matrix->_values[5] * copy[13] +
	    matrix->_values[9] * copy[14] +
	    matrix->_values[13] * copy[15];
	_values[14] = matrix->_values[2] * copy[12] +
	    matrix->_values[6] * copy[13] +
	    matrix->_values[10] * copy[14] +
	    matrix->_values[14] * copy[15];
	_values[15] = matrix->_values[3] * copy[12] +
	    matrix->_values[7] * copy[13] +
	    matrix->_values[11] * copy[14] +
	    matrix->_values[15] * copy[15];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OF4x4Matrix: {\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"}>",
	    _values[0], _values[4], _values[8], _values[12],
	    _values[1], _values[5], _values[9], _values[13],
	    _values[2], _values[6], _values[10], _values[14],
	    _values[3], _values[7], _values[11], _values[15]];
}
@end