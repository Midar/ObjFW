/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFINISection.h"
#import "OFINISection+Private.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@interface OFINISectionPair: OFObject
{
@public
	OFString *_key, *_value;
}
@end

@interface OFINISectionComment: OFObject
{
@public
	OFString *_comment;
}
@end

static OFString *
escapeString(OFString *string)
{
	OFMutableString *mutableString;

	/* FIXME: Optimize */
	if (![string hasPrefix: @" "] && ![string hasPrefix: @"\t"] &&
	    ![string hasPrefix: @"\f"] && ![string hasSuffix: @" "] &&
	    ![string hasSuffix: @"\t"] && ![string hasSuffix: @"\f"] &&
	    ![string containsString: @"\""])
		return string;

	mutableString = [[string mutableCopy] autorelease];

	[mutableString replaceOccurrencesOfString: @"\\" withString: @"\\\\"];
	[mutableString replaceOccurrencesOfString: @"\f" withString: @"\\f"];
	[mutableString replaceOccurrencesOfString: @"\r" withString: @"\\r"];
	[mutableString replaceOccurrencesOfString: @"\n" withString: @"\\n"];
	[mutableString replaceOccurrencesOfString: @"\"" withString: @"\\\""];

	[mutableString insertString: @"\"" atIndex: 0];
	[mutableString appendString: @"\""];

	[mutableString makeImmutable];

	return mutableString;
}

static OFString *
unescapeString(OFString *string)
{
	OFMutableString *mutableString;

	if (![string hasPrefix: @"\""] || ![string hasSuffix: @"\""])
		return string;

	string = [string substringWithRange: OFMakeRange(1, string.length - 2)];
	mutableString = [[string mutableCopy] autorelease];

	[mutableString replaceOccurrencesOfString: @"\\f" withString: @"\f"];
	[mutableString replaceOccurrencesOfString: @"\\r" withString: @"\r"];
	[mutableString replaceOccurrencesOfString: @"\\n" withString: @"\n"];
	[mutableString replaceOccurrencesOfString: @"\\\"" withString: @"\""];
	[mutableString replaceOccurrencesOfString: @"\\\\" withString: @"\\"];

	[mutableString makeImmutable];

	return mutableString;
}

@implementation OFINISectionPair
- (void)dealloc
{
	[_key release];
	[_value release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"%@ = %@", _key, _value];
}
@end

@implementation OFINISectionComment
- (void)dealloc
{
	[_comment release];

	[super dealloc];
}

- (OFString *)description
{
	return [[_comment copy] autorelease];
}
@end

@implementation OFINISection
@synthesize name = _name;

- (instancetype)of_initWithName: (OFString *)name OF_DIRECT
{
	self = [super init];

	@try {
		_name = [name copy];
		_lines = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_name release];
	[_lines release];

	[super dealloc];
}

- (void)of_parseLine: (OFString *)line
{
	if (![line hasPrefix: @";"]) {
		OFINISectionPair *pair;
		OFString *key, *value;
		size_t pos;

		if (_name == nil)
			@throw [OFInvalidFormatException exception];

		pair = [[[OFINISectionPair alloc] init] autorelease];

		if ((pos = [line rangeOfString: @"="].location) == OFNotFound)
			@throw [OFInvalidFormatException exception];

		key = unescapeString([line substringToIndex: pos]
		    .stringByDeletingEnclosingWhitespaces);
		value = unescapeString([line substringFromIndex: pos + 1]
		    .stringByDeletingEnclosingWhitespaces);

		pair->_key = [key copy];
		pair->_value = [value copy];

		[_lines addObject: pair];
	} else {
		OFINISectionComment *comment =
		    [[[OFINISectionComment alloc] init] autorelease];

		comment->_comment = [line copy];

		[_lines addObject: comment];
	}
}

- (OFString *)stringValueForKey: (OFString *)key
{
	return [self stringValueForKey: key defaultValue: nil];
}

- (OFString *)stringValueForKey: (OFString *)key
		   defaultValue: (OFString *)defaultValue
{
	for (id line in _lines) {
		OFINISectionPair *pair;

		if (![line isKindOfClass: [OFINISectionPair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key])
			return [[pair->_value copy] autorelease];
	}

	return defaultValue;
}

- (long long)longLongValueForKey: (OFString *)key
		    defaultValue: (long long)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringValueForKey: key defaultValue: nil];
	long long ret;

	if (value != nil)
		ret = [value longLongValueWithBase: 0];
	else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)boolValueForKey: (OFString *)key defaultValue: (bool)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringValueForKey: key defaultValue: nil];
	bool ret;

	if (value != nil) {
		if ([value isEqual: @"true"])
			ret = true;
		else if ([value isEqual: @"false"])
			ret = false;
		else
			@throw [OFInvalidFormatException exception];
	} else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (float)floatValueForKey: (OFString *)key defaultValue: (float)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringValueForKey: key defaultValue: nil];
	float ret;

	if (value != nil)
		ret = value.floatValue;
	else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (double)doubleValueForKey: (OFString *)key defaultValue: (double)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringValueForKey: key defaultValue: nil];
	double ret;

	if (value != nil)
		ret = value.doubleValue;
	else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray OF_GENERIC(OFString *) *)arrayValueForKey: (OFString *)key
{
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (id line in _lines) {
		OFINISectionPair *pair;

		if (![line isKindOfClass: [OFINISectionPair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key])
			[ret addObject: [[pair->_value copy] autorelease]];
	}

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}

- (void)setStringValue: (OFString *)string forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();
	OFINISectionPair *pair;

	for (id line in _lines) {
		if (![line isKindOfClass: [OFINISectionPair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key]) {
			OFString *old = pair->_value;
			pair->_value = [string copy];
			[old release];

			objc_autoreleasePoolPop(pool);

			return;
		}
	}

	pair = [[[OFINISectionPair alloc] init] autorelease];
	pair->_key = nil;
	pair->_value = nil;

	@try {
		pair->_key = [key copy];
		pair->_value = [string copy];
		[_lines addObject: pair];
	} @catch (id e) {
		[pair->_key release];
		[pair->_value release];

		@throw e;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setLongLongValue: (long long)longLongValue forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setStringValue: [OFString stringWithFormat:
				  @"%lld", longLongValue]
		      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBoolValue: (bool)boolValue forKey: (OFString *)key
{
	[self setStringValue: (boolValue ? @"true" : @"false") forKey: key];
}

- (void)setFloatValue: (float)floatValue forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setStringValue: [OFString stringWithFormat: @"%g", floatValue]
		      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDoubleValue: (double)doubleValue forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setStringValue: [OFString stringWithFormat: @"%g", doubleValue]
		      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setArrayValue: (OFArray OF_GENERIC(OFString *) *)arrayValue
	       forKey: (OFString *)key
{
	void *pool;
	OFMutableArray *pairs;
	id const *lines;
	size_t count;
	bool replaced;

	if (arrayValue.count == 0) {
		[self removeValueForKey: key];
		return;
	}

	pool = objc_autoreleasePoolPush();

	pairs = [OFMutableArray arrayWithCapacity: arrayValue.count];

	for (OFString *string in arrayValue) {
		OFINISectionPair *pair;

		if (![string isKindOfClass: [OFString class]])
			@throw [OFInvalidArgumentException exception];

		pair = [[[OFINISectionPair alloc] init] autorelease];
		pair->_key = [key copy];
		pair->_value = [string copy];

		[pairs addObject: pair];
	}

	lines = _lines.objects;
	count = _lines.count;
	replaced = false;

	for (size_t i = 0; i < count; i++) {
		OFINISectionPair *pair;

		if (![lines[i] isKindOfClass: [OFINISectionPair class]])
			continue;

		pair = lines[i];

		if ([pair->_key isEqual: key]) {
			[_lines removeObjectAtIndex: i];

			if (!replaced) {
				[_lines insertObjectsFromArray: pairs
						       atIndex: i];

				replaced = true;
				/* Continue after inserted pairs */
				i += arrayValue.count - 1;
			} else
				i--;	/* Continue at same position */

			lines = _lines.objects;
			count = _lines.count;

			continue;
		}
	}

	if (!replaced)
		[_lines addObjectsFromArray: pairs];

	objc_autoreleasePoolPop(pool);
}

- (void)removeValueForKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();
	id const *lines = _lines.objects;
	size_t count = _lines.count;

	for (size_t i = 0; i < count; i++) {
		OFINISectionPair *pair;

		if (![lines[i] isKindOfClass: [OFINISectionPair class]])
			continue;

		pair = lines[i];

		if ([pair->_key isEqual: key]) {
			[_lines removeObjectAtIndex: i];

			lines = _lines.objects;
			count = _lines.count;

			i--;	/* Continue at same position */
			continue;
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (bool)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding
		   first: (bool)first
{
	if (_lines.count == 0)
		return false;

	if (_name != nil) {
		if (first)
			[stream writeFormat: @"[%@]\r\n", _name];
		else
			[stream writeFormat: @"\r\n[%@]\r\n", _name];
	}

	for (id line in _lines) {
		if ([line isKindOfClass: [OFINISectionComment class]]) {
			OFINISectionComment *comment = line;
			[stream writeFormat: @"%@\r\n", comment->_comment];
		} else if ([line isKindOfClass: [OFINISectionPair class]]) {
			OFINISectionPair *pair = line;
			OFString *key = escapeString(pair->_key);
			OFString *value = escapeString(pair->_value);
			OFString *tmp = [OFString
			    stringWithFormat: @"%@=%@\r\n", key, value];
			[stream writeString: tmp encoding: encoding];
		} else
			@throw [OFInvalidArgumentException exception];
	}

	return true;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@ \"%@\": %@>",
					   self.class, _name, _lines];
}
@end
