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

#import "TestsAppDelegate.h"

static OFString *module;

@implementation TestsAppDelegate (OFINIFileTests)
- (void)INIFileTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *output = @"[tests]\r\n"
	    @"foo=baz\r\n"
	    @"foobar=baz\r\n"
	    @";comment\r\n"
	    @"new=new\r\n"
	    @"\r\n"
	    @"[foobar]\r\n"
	    @";foobarcomment\r\n"
	    @"qux=\" asd\"\r\n"
	    @"quxquxqux=\"hello\\\"wörld\"\r\n"
	    @"qux2=\"a\\f\"\r\n"
	    @"qux3=a\fb\r\n"
	    @"\r\n"
	    @"[types]\r\n"
	    @"integer=16\r\n"
	    @"bool=false\r\n"
	    @"float=0.25\r\n"
	    @"array1=foo\r\n"
	    @"array1=bar\r\n"
	    @"double=0.75\r\n";
	OFIRI *IRI;
	OFINIFile *file;
	OFINICategory *tests, *foobar, *types;
	OFArray *array;
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	OFIRI *writeIRI;
#endif

	module = @"OFINIFile";

	IRI = [OFIRI IRIWithString: @"embedded:testfile.ini"];
	TEST(@"+[fileWithIRI:encoding:]",
	    (file = [OFINIFile fileWithIRI: IRI
				  encoding: OFStringEncodingCodepage437]))

	tests = [file categoryForName: @"tests"];
	foobar = [file categoryForName: @"foobar"];
	types = [file categoryForName: @"types"];
	TEST(@"-[categoryForName:]",
	    tests != nil && foobar != nil && types != nil)

	module = @"OFINICategory";

	TEST(@"-[stringValueForKey:]",
	    [[tests stringValueForKey: @"foo"] isEqual: @"bar"] &&
	    [[foobar stringValueForKey: @"quxquxqux"] isEqual: @"hello\"wörld"])

	TEST(@"-[setStringValue:forKey:]",
	    R([tests setStringValue: @"baz" forKey: @"foo"]) &&
	    R([tests setStringValue: @"new" forKey: @"new"]) &&
	    R([foobar setStringValue: @"a\fb" forKey: @"qux3"]))

	TEST(@"-[longLongValueForKey:defaultValue:]",
	    [types longLongValueForKey: @"integer" defaultValue: 2] == 0x20)

	TEST(@"-[setLongLongValue:forKey:]",
	    R([types setLongLongValue: 0x10 forKey: @"integer"]))

	TEST(@"-[boolValueForKey:defaultValue:]",
	    [types boolValueForKey: @"bool" defaultValue: false] == true)

	TEST(@"-[setBoolValue:forKey:]",
	    R([types setBoolValue: false forKey: @"bool"]))

	TEST(@"-[floatValueForKey:defaultValue:]",
	    [types floatValueForKey: @"float" defaultValue: 1] == 0.5f)

	TEST(@"-[setFloatValue:forKey:]",
	    R([types setFloatValue: 0.25f forKey: @"float"]))

	TEST(@"-[doubleValueForKey:defaultValue:]",
	    [types doubleValueForKey: @"double" defaultValue: 3] == 0.25)

	TEST(@"-[setDoubleValue:forKey:]",
	    R([types setDoubleValue: 0.75 forKey: @"double"]))

	array = [OFArray arrayWithObjects: @"1", @"2", nil];
	TEST(@"-[arrayValueForKey:]",
	    [[types arrayValueForKey: @"array1"] isEqual: array] &&
	    [[types arrayValueForKey: @"array2"] isEqual: array] &&
	    [[types arrayValueForKey: @"array3"] isEqual: [OFArray array]])

	array = [OFArray arrayWithObjects: @"foo", @"bar", nil];
	TEST(@"-[setArrayValue:forKey:]",
	    R([types setArrayValue: array forKey: @"array1"]))

	TEST(@"-[removeValueForKey:]",
	    R([foobar removeValueForKey: @"quxqux "]) &&
	    R([types removeValueForKey: @"array2"]))

	module = @"OFINIFile";

	/* FIXME: Find a way to write files on Nintendo DS */
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	writeIRI = [OFSystemInfo temporaryDirectoryIRI];
	if (writeIRI == nil)
		writeIRI = [[OFFileManager defaultManager] currentDirectoryIRI];
	writeIRI = [writeIRI IRIByAppendingPathComponent: @"objfw-tests.ini"
					     isDirectory: false];
	TEST(@"-[writeToFile:encoding:]",
	    R([file writeToIRI: writeIRI
		      encoding: OFStringEncodingCodepage437]) &&
	    [[OFString stringWithContentsOfIRI: writeIRI
				      encoding: OFStringEncodingCodepage437]
	    isEqual: output])
	[[OFFileManager defaultManager] removeItemAtIRI: writeIRI];
#else
	(void)output;
#endif

	objc_autoreleasePoolPop(pool);
}
@end
