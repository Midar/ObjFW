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

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"
#import "OFASPrintF.h"
#import "OFMutableUTF8String.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "unicode.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableStringPlaceholder: OFMutableString
@end

@implementation OFMutableStringPlaceholder
- (instancetype)init
{
	return (id)[[OFMutableUTF8String alloc] init];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF8String: UTF8String];
}

- (instancetype)initWithUTF8String: (const char *)UTF8String
			    length: (size_t)UTF8StringLength
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithUTF8String: UTF8String
			length: UTF8StringLength];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
{
	return (id)[[OFMutableUTF8String alloc] initWithCString: cString
						       encoding: encoding];
}

- (instancetype)initWithCString: (const char *)cString
		       encoding: (OFStringEncoding)encoding
			 length: (size_t)cStringLength
{
	return (id)[[OFMutableUTF8String alloc] initWithCString: cString
						       encoding: encoding
							 length: cStringLength];
}

- (instancetype)initWithString: (OFString *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithString: string];
}

- (instancetype)initWithCharacters: (const OFUnichar *)characters
			    length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithCharacters: characters
							    length: length];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							      length: length];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF16String: (const OFChar16 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF16String: string
							     length: length
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							     length: length];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							  byteOrder: byteOrder];
}

- (instancetype)initWithUTF32String: (const OFChar32 *)string
			     length: (size_t)length
			  byteOrder: (OFByteOrder)byteOrder
{
	return (id)[[OFMutableUTF8String alloc] initWithUTF32String: string
							     length: length
							  byteOrder: byteOrder];
}

- (instancetype)initWithFormat: (OFConstantString *)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[OFMutableUTF8String alloc] initWithFormat: format
						arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithFormat: (OFConstantString *)format
		     arguments: (va_list)arguments
{
	return (id)[[OFMutableUTF8String alloc] initWithFormat: format
						     arguments: arguments];
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	return (id)[[OFMutableUTF8String alloc] initWithContentsOfFile: path];
}

- (instancetype)initWithContentsOfFile: (OFString *)path
			      encoding: (OFStringEncoding)encoding
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithContentsOfFile: path
			  encoding: encoding];
}
#endif

- (instancetype)initWithContentsOfURL: (OFURL *)URL
{
	return (id)[[OFMutableUTF8String alloc] initWithContentsOfURL: URL];
}

- (instancetype)initWithContentsOfURL: (OFURL *)URL
			     encoding: (OFStringEncoding)encoding
{
	return (id)[[OFMutableUTF8String alloc]
	    initWithContentsOfURL: URL
			 encoding: encoding];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMutableUTF8String alloc] initWithSerialization: element];
}

- (instancetype)retain
{
	return self;
}

- (instancetype)autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end

@implementation OFMutableString
+ (void)initialize
{
	if (self == [OFMutableString class])
		placeholder.isa = [OFMutableStringPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFMutableString class])
		return (id)&placeholder;

	return [super alloc];
}

#ifdef OF_HAVE_UNICODE_TABLES
- (void)of_convertWithWordStartTable: (const OFUnichar *const [])startTable
		     wordMiddleTable: (const OFUnichar *const [])middleTable
		  wordStartTableSize: (size_t)startTableSize
		 wordMiddleTableSize: (size_t)middleTableSize
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	bool isStart = true;

	for (size_t i = 0; i < length; i++) {
		const OFUnichar *const *table;
		size_t tableSize;
		OFUnichar c = characters[i];

		if (isStart) {
			table = startTable;
			tableSize = middleTableSize;
		} else {
			table = middleTable;
			tableSize = middleTableSize;
		}

		if (c >> 8 < tableSize && table[c >> 8][c & 0xFF])
			[self setCharacter: table[c >> 8][c & 0xFF] atIndex: i];

		isStart = OFASCIIIsSpace(c);
	}

	objc_autoreleasePoolPop(pool);
}
#else
static void
convert(OFMutableString *self, char (*startFunction)(char),
    char (*middleFunction)(char))
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	bool isStart = true;

	for (size_t i = 0; i < length; i++) {
		char (*function)(char) =
		    (isStart ? startFunction : middleFunction);
		OFUnichar c = characters[i];

		if (c <= 0x7F)
			[self setCharacter: (int)function(c) atIndex: i];

		isStart = OFASCIIIsSpace(c);
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)setCharacter: (OFUnichar)character atIndex: (size_t)idx
{
	void *pool = objc_autoreleasePoolPush();
	OFString *string =
	    [OFString stringWithCharacters: &character length: 1];
	[self replaceCharactersInRange: OFRangeMake(idx, 1) withString: string];
	objc_autoreleasePoolPop(pool);
}

- (void)appendString: (OFString *)string
{
	[self insertString: string atIndex: self.length];
}

- (void)appendCharacters: (const OFUnichar *)characters
		  length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	[self appendString: [OFString stringWithCharacters: characters
						    length: length]];
	objc_autoreleasePoolPop(pool);
}

- (void)appendUTF8String: (const char *)UTF8String
{
	void *pool = objc_autoreleasePoolPush();
	[self appendString: [OFString stringWithUTF8String: UTF8String]];
	objc_autoreleasePoolPop(pool);
}

- (void)appendUTF8String: (const char *)UTF8String
		  length: (size_t)UTF8StringLength
{
	void *pool = objc_autoreleasePoolPush();
	[self appendString: [OFString stringWithUTF8String: UTF8String
						    length: UTF8StringLength]];
	objc_autoreleasePoolPop(pool);
}

- (void)appendCString: (const char *)cString
	     encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	[self appendString: [OFString stringWithCString: cString
					       encoding: encoding]];
	objc_autoreleasePoolPop(pool);
}

- (void)appendCString: (const char *)cString
	     encoding: (OFStringEncoding)encoding
	       length: (size_t)cStringLength
{
	void *pool = objc_autoreleasePoolPush();
	[self appendString: [OFString stringWithCString: cString
					       encoding: encoding
						 length: cStringLength]];
	objc_autoreleasePoolPop(pool);
}

- (void)appendFormat: (OFConstantString *)format, ...
{
	va_list arguments;

	va_start(arguments, format);
	[self appendFormat: format
		 arguments: arguments];
	va_end(arguments);
}

- (void)appendFormat: (OFConstantString *)format arguments: (va_list)arguments
{
	char *UTF8String;
	int UTF8StringLength;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((UTF8StringLength = OFVASPrintF(&UTF8String, format.UTF8String,
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		[self appendUTF8String: UTF8String length: UTF8StringLength];
	} @finally {
		free(UTF8String);
	}
}

- (void)prependString: (OFString *)string
{
	[self insertString: string atIndex: 0];
}

- (void)reverse
{
	size_t i, j, length = self.length;

	for (i = 0, j = length - 1; i < length / 2; i++, j--) {
		OFUnichar tmp = [self characterAtIndex: j];
		[self setCharacter: [self characterAtIndex: i] atIndex: j];
		[self setCharacter: tmp atIndex: i];
	}
}

#ifdef OF_HAVE_UNICODE_TABLES
- (void)uppercase
{
	[self of_convertWithWordStartTable: OFUnicodeUppercaseTable
			   wordMiddleTable: OFUnicodeUppercaseTable
			wordStartTableSize: OFUnicodeUppercaseTableSize
		       wordMiddleTableSize: OFUnicodeUppercaseTableSize];
}

- (void)lowercase
{
	[self of_convertWithWordStartTable: OFUnicodeLowercaseTable
			   wordMiddleTable: OFUnicodeLowercaseTable
			wordStartTableSize: OFUnicodeLowercaseTableSize
		       wordMiddleTableSize: OFUnicodeLowercaseTableSize];
}

- (void)capitalize
{
	[self of_convertWithWordStartTable: OFUnicodeTitlecaseTable
			   wordMiddleTable: OFUnicodeLowercaseTable
			wordStartTableSize: OFUnicodeTitlecaseTableSize
		       wordMiddleTableSize: OFUnicodeLowercaseTableSize];
}
#else
- (void)uppercase
{
	convert(self, OFASCIIToUpper, OFASCIIToUpper);
}

- (void)lowercase
{
	convert(self, OFASCIIToLower, OFASCIIToLower);
}

- (void)capitalize
{
	convert(self, OFASCIIToUpper, OFASCIIToLower);
}
#endif

- (void)insertString: (OFString *)string atIndex: (size_t)idx
{
	[self replaceCharactersInRange: OFRangeMake(idx, 0) withString: string];
}

- (void)deleteCharactersInRange: (OFRange)range
{
	[self replaceCharactersInRange: range withString: @""];
}

- (void)replaceCharactersInRange: (OFRange)range
		      withString: (OFString *)replacement
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
{
	[self replaceOccurrencesOfString: string
			      withString: replacement
				 options: 0
				   range: OFRangeMake(0, self.length)];
}

- (void)replaceOccurrencesOfString: (OFString *)string
			withString: (OFString *)replacement
			   options: (int)options
			     range: (OFRange)range
{
	void *pool = objc_autoreleasePoolPush(), *pool2;
	const OFUnichar *characters;
	const OFUnichar *searchCharacters = string.characters;
	size_t searchLength = string.length;
	size_t replacementLength = replacement.length;

	if (string == nil || replacement == nil)
		@throw [OFInvalidArgumentException exception];

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > self.length)
		@throw [OFOutOfRangeException exception];

	if (searchLength > range.length) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	pool2 = objc_autoreleasePoolPush();
	characters = self.characters;

	for (size_t i = range.location; i <= range.length - searchLength; i++) {
		if (memcmp(characters + i, searchCharacters,
		    searchLength * sizeof(OFUnichar)) != 0)
			continue;

		[self replaceCharactersInRange: OFRangeMake(i, searchLength)
				    withString: replacement];

		range.length -= searchLength;
		range.length += replacementLength;

		i += replacementLength - 1;

		objc_autoreleasePoolPop(pool2);
		pool2 = objc_autoreleasePoolPush();

		characters = self.characters;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)deleteLeadingWhitespaces
{
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
	size_t i, length = self.length;

	for (i = 0; i < length; i++) {
		OFUnichar c = characters[i];

		if (!OFASCIIIsSpace(c))
			break;
	}

	objc_autoreleasePoolPop(pool);

	[self deleteCharactersInRange: OFRangeMake(0, i)];
}

- (void)deleteTrailingWhitespaces
{
	void *pool;
	const OFUnichar *characters, *p;
	size_t length, d;

	length = self.length;

	if (length == 0)
		return;

	pool = objc_autoreleasePoolPush();
	characters = self.characters;

	d = 0;
	for (p = characters + length - 1; p >= characters; p--) {
		if (!OFASCIIIsSpace(*p))
			break;

		d++;
	}

	objc_autoreleasePoolPop(pool);

	[self deleteCharactersInRange: OFRangeMake(length - d, d)];
}

- (void)deleteEnclosingWhitespaces
{
	[self deleteLeadingWhitespaces];
	[self deleteTrailingWhitespaces];
}

- (id)copy
{
	return [[OFString alloc] initWithString: self];
}

- (void)makeImmutable
{
}
@end
