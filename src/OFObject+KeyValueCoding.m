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

#include <stdlib.h>

#import "OFObject.h"
#import "OFObject+KeyValueCoding.h"
#import "OFArray.h"
#import "OFMethodSignature.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFUndefinedKeyException.h"

int _OFObject_KeyValueCoding_reference;

@implementation OFObject (KeyValueCoding)
- (id)valueForKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();
	SEL selector = sel_registerName(key.UTF8String);
	OFMethodSignature *methodSignature =
	    [self methodSignatureForSelector: selector];
	id ret;

	if (methodSignature == nil) {
		size_t keyLength;
		char *name;

		if ((keyLength = key.UTF8StringLength) < 1) {
			objc_autoreleasePoolPop(pool);
			return [self valueForUndefinedKey: key];
		}

		name = of_alloc(keyLength + 3, 1);
		@try {
			memcpy(name, "is", 2);
			memcpy(name + 2, key.UTF8String, keyLength);
			name[keyLength + 2] = '\0';

			name[2] = of_ascii_toupper(name[2]);

			selector = sel_registerName(name);
		} @finally {
			free(name);
		}

		methodSignature = [self methodSignatureForSelector: selector];

		if (methodSignature == NULL) {
			objc_autoreleasePoolPop(pool);
			return [self valueForUndefinedKey: key];
		}

		switch (*methodSignature.methodReturnType) {
		case '@':
		case '#':
			objc_autoreleasePoolPop(pool);
			return [self valueForUndefinedKey: key];
		}
	}

	if (methodSignature.numberOfArguments != 2 ||
	    *[methodSignature argumentTypeAtIndex: 0] != '@' ||
	    *[methodSignature argumentTypeAtIndex: 1] != ':') {
		objc_autoreleasePoolPop(pool);
		return [self valueForUndefinedKey: key];
	}

	switch (*methodSignature.methodReturnType) {
	case '@':
	case '#':
		ret = [self performSelector: selector];
		break;
#define CASE(encoding, type, method)					  \
	case encoding:							  \
		{							  \
			type (*getter)(id, SEL) = (type (*)(id, SEL))	  \
			    [self methodForSelector: selector];		  \
			ret = [OFNumber method getter(self, selector)]; \
		}							  \
		break;
	CASE('B', bool, numberWithBool:)
	CASE('c', char, numberWithChar:)
	CASE('s', short, numberWithShort:)
	CASE('i', int, numberWithInt:)
	CASE('l', long, numberWithLong:)
	CASE('q', long long, numberWithLongLong:)
	CASE('C', unsigned char, numberWithUnsignedChar:)
	CASE('S', unsigned short, numberWithUnsignedShort:)
	CASE('I', unsigned int, numberWithUnsignedInt:)
	CASE('L', unsigned long, numberWithUnsignedLong:)
	CASE('Q', unsigned long long, numberWithUnsignedLongLong:)
	CASE('f', float, numberWithFloat:)
	CASE('d', double, numberWithDouble:)
#undef CASE
	default:
		objc_autoreleasePoolPop(pool);
		return [self valueForUndefinedKey: key];
	}

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (id)valueForKeyPath: (OFString *)keyPath
{
	void *pool = objc_autoreleasePoolPush();
	id ret = self;

	for (OFString *key in [keyPath componentsSeparatedByString: @"."])
		ret = [ret valueForKey: key];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (id)valueForUndefinedKey: (OFString *)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self key: key];
}

- (void)setValue: (id)value forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();
	size_t keyLength;
	char *name;
	SEL selector;
	OFMethodSignature *methodSignature;
	const char *valueType;

	if ((keyLength = key.UTF8StringLength) < 1) {
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	name = of_alloc(keyLength + 5, 1);
	@try {
		memcpy(name, "set", 3);
		memcpy(name + 3, key.UTF8String, keyLength);
		memcpy(name + keyLength + 3, ":", 2);

		name[3] = of_ascii_toupper(name[3]);

		selector = sel_registerName(name);
	} @finally {
		free(name);
	}

	methodSignature = [self methodSignatureForSelector: selector];

	if (methodSignature == nil ||
	    methodSignature.numberOfArguments != 3 ||
	    *methodSignature.methodReturnType != 'v' ||
	    *[methodSignature argumentTypeAtIndex: 0] != '@' ||
	    *[methodSignature argumentTypeAtIndex: 1] != ':') {
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	valueType = [methodSignature argumentTypeAtIndex: 2];

	if (*valueType != '@' && *valueType != '#' && value == nil) {
		objc_autoreleasePoolPop(pool);
		[self setNilValueForKey: key];
		return;
	}

	switch (*valueType) {
	case '@':
	case '#':
		{
			void (*setter)(id, SEL, id) = (void (*)(id, SEL, id))
			    [self methodForSelector: selector];
			setter(self, selector, value);
		}
		break;
#define CASE(encoding, type, method) \
	case encoding:						\
		{						\
			void (*setter)(id, SEL, type) =		\
			    (void (*)(id, SEL, type))		\
			    [self methodForSelector: selector];	\
			setter(self, selector, [value method]);	\
		}						\
		break;
	CASE('B', bool, boolValue)
	CASE('c', char, charValue)
	CASE('s', short, shortValue)
	CASE('i', int, intValue)
	CASE('l', long, longValue)
	CASE('q', long long, longLongValue)
	CASE('C', unsigned char, unsignedCharValue)
	CASE('S', unsigned short, unsignedShortValue)
	CASE('I', unsigned int, unsignedIntValue)
	CASE('L', unsigned long, unsignedLongValue)
	CASE('Q', unsigned long long, unsignedLongLongValue)
	CASE('f', float, floatValue)
	CASE('d', double, doubleValue)
#undef CASE
	default:
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setValue: (id)value forKeyPath: (OFString *)keyPath
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *keys = [keyPath componentsSeparatedByString: @"."];
	size_t keysCount = keys.count;
	id object = self;
	size_t i = 0;

	for (OFString *key in keys) {
		if (++i == keysCount)
			[object setValue: value forKey: key];
		else
			object = [object valueForKey: key];
	}

	objc_autoreleasePoolPop(pool);
}

-  (void)setValue: (id)value forUndefinedKey: (OFString *)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self
							key: key
						      value: value];
}

- (void)setNilValueForKey: (OFString *)key
{
	@throw [OFInvalidArgumentException exception];
}
@end
