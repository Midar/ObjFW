/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#include <math.h>

#import "OFColor.h"
#import "OFConcreteColor.h"
#import "OFOnce.h"
#import "OFString.h"
#import "OFTaggedPointerColor.h"

@interface OFColorSingleton: OFConcreteColor
@end

@interface OFPlaceholderColor: OFColor
@end

static struct {
	Class isa;
} placeholder;

#ifdef OF_OBJFW_RUNTIME
static const float allowedImprecision = 0.0000001;
#endif

@implementation OFPlaceholderColor
- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha
{
#ifdef OF_OBJFW_RUNTIME
	uint8_t redInt = nearbyintf(red * 255);
	uint8_t greenInt = nearbyintf(green * 255);
	uint8_t blueInt = nearbyintf(blue * 255);

	if (fabsf(red * 255 - redInt) < allowedImprecision &&
	    fabsf(green * 255 - greenInt) < allowedImprecision &&
	    fabsf(blue * 255 - blueInt) < allowedImprecision && alpha == 1) {
		id ret = [OFTaggedPointerColor colorWithRed: redInt
						      green: greenInt
						       blue: blueInt];

		if (ret != nil)
			return ret;
	}
#endif

	return (id)[[OFConcreteColor alloc] initWithRed: red
						  green: green
						   blue: blue
						  alpha: alpha];
}

OF_SINGLETON_METHODS
@end

@implementation OFColorSingleton
OF_SINGLETON_METHODS
@end

@implementation OFColor
+ (void)initialize
{
	if (self == [OFColor class])
		object_setClass((id)&placeholder, [OFPlaceholderColor class]);
}

+ (instancetype)alloc
{
	if (self == [OFColor class])
		return (id)&placeholder;

	return [super alloc];
}

#define PREDEFINED_COLOR(name, redValue, greenValue, blueValue)		   \
	static OFColor *name##Color = nil;				   \
									   \
	static void							   \
	initPredefinedColor_##name(void)				   \
	{								   \
		name##Color = [[OFColorSingleton alloc]			   \
		    initWithRed: redValue				   \
			  green: greenValue				   \
			   blue: blueValue				   \
			  alpha: 1];					   \
	}								   \
									   \
	+ (OFColor *)name						   \
	{								   \
		static OFOnceControl onceControl = OFOnceControlInitValue; \
		OFOnce(&onceControl, initPredefinedColor_##name);	   \
									   \
		return name##Color;					   \
	}

PREDEFINED_COLOR(black,   0.00f, 0.00f, 0.00f)
PREDEFINED_COLOR(silver,  0.75f, 0.75f, 0.75f)
PREDEFINED_COLOR(grey,    0.50f, 0.50f, 0.50f)
PREDEFINED_COLOR(white,   1.00f, 1.00f, 1.00f)
PREDEFINED_COLOR(maroon,  0.50f, 0.00f, 0.00f)
PREDEFINED_COLOR(red,     1.00f, 0.00f, 0.00f)
PREDEFINED_COLOR(purple,  0.50f, 0.00f, 0.50f)
PREDEFINED_COLOR(fuchsia, 1.00f, 0.00f, 1.00f)
PREDEFINED_COLOR(green,   0.00f, 0.50f, 0.00f)
PREDEFINED_COLOR(lime,    0.00f, 1.00f, 0.00f)
PREDEFINED_COLOR(olive,   0.50f, 0.50f, 0.00f)
PREDEFINED_COLOR(yellow,  1.00f, 1.00f, 0.00f)
PREDEFINED_COLOR(navy,    0.00f, 0.00f, 0.50f)
PREDEFINED_COLOR(blue,    0.00f, 0.00f, 1.00f)
PREDEFINED_COLOR(teal,    0.00f, 0.50f, 0.50f)
PREDEFINED_COLOR(aqua,    0.00f, 1.00f, 1.00f)

+ (instancetype)colorWithRed: (float)red
		       green: (float)green
			blue: (float)blue
		       alpha: (float)alpha
{
	return [[[self alloc] initWithRed: red
				    green: green
				     blue: blue
				    alpha: alpha] autorelease];
}

- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha
{
	if ([self isMemberOfClass: [OFColor class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (bool)isEqual: (id)object
{
	OFColor *other;
	float red, green, blue, alpha;
	float otherRed, otherGreen, otherBlue, otherAlpha;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFColor class]])
		return false;

	other = object;
	[self getRed: &red green: &green blue: &blue alpha: &alpha];
	[other getRed: &otherRed
		green: &otherGreen
		 blue: &otherBlue
		alpha: &otherAlpha];

	if (otherRed != red)
		return false;
	if (otherGreen != green)
		return false;
	if (otherBlue != blue)
		return false;
	if (otherAlpha != alpha)
		return false;

	return true;
}

- (unsigned long)hash
{
	float red, green, blue, alpha;
	unsigned long hash;
	float tmp;

	[self getRed: &red green: &green blue: &blue alpha: &alpha];

	OFHashInit(&hash);

	tmp = OFToLittleEndianFloat(red);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(green);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(blue);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(alpha);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	OFHashFinalize(&hash);

	return hash;
}

- (void)getRed: (float *)red
	 green: (float *)green
	  blue: (float *)blue
	 alpha: (float *)alpha
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	float red, green, blue, alpha;

	[self getRed: &red green: &green blue: &blue alpha: &alpha];

	return [OFString stringWithFormat:
	    @"<%@ red=%f green=%f blue=%f alpha=%f>",
	    self.class, red, green, blue, alpha];
}
@end
