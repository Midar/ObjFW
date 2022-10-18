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

#import "OFMutableURI.h"
#import "OFURI+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
#endif
#import "OFNumber.h"
#import "OFPair.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFMutableURI
@dynamic scheme, host, percentEncodedHost, port, user, percentEncodedUser;
@dynamic password, percentEncodedPassword, path, percentEncodedPath;
@dynamic pathComponents, query, percentEncodedQuery, queryItems, fragment;
@dynamic percentEncodedFragment;

+ (instancetype)URIWithScheme: (OFString *)scheme
{
	return [[[self alloc] initWithScheme: scheme] autorelease];
}

- (instancetype)initWithScheme: (OFString *)scheme
{
	self = [super of_init];

	@try {
		self.scheme = scheme;
		_percentEncodedPath = @"";
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setScheme: (OFString *)scheme
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _scheme;

	if (scheme.length < 1 || !OFASCIIIsAlpha(*scheme.UTF8String))
		@throw [OFInvalidFormatException exception];

	OFURIVerifyIsEscaped(scheme,
	    [OFCharacterSet URISchemeAllowedCharacterSet], false);

	_scheme = [scheme.lowercaseString copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedHost;

	if (OFURIIsIPv6Host(host))
		_percentEncodedHost = [[OFString alloc]
		    initWithFormat: @"[%@]", host];
	else
		_percentEncodedHost = [[host
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    [OFCharacterSet URIHostAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedHost: (OFString *)percentEncodedHost
{
	OFString *old;

	if ([percentEncodedHost hasPrefix: @"["] &&
	    [percentEncodedHost hasSuffix: @"]"]) {
		if (!OFURIIsIPv6Host([percentEncodedHost substringWithRange:
		    OFMakeRange(1, percentEncodedHost.length - 2)]))
			@throw [OFInvalidFormatException exception];
	} else if (percentEncodedHost != nil)
		OFURIVerifyIsEscaped(percentEncodedHost,
		    [OFCharacterSet URIHostAllowedCharacterSet], true);

	old = _percentEncodedHost;
	_percentEncodedHost = [percentEncodedHost copy];
	[old release];
}

- (void)setPort: (OFNumber *)port
{
	OFNumber *old = _port;

	if (port.longLongValue < 0 || port.longLongValue > 65535)
		@throw [OFInvalidArgumentException exception];

	_port = [port copy];
	[old release];
}

- (void)setUser: (OFString *)user
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedUser;

	_percentEncodedUser = [[user
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIUserAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedUser: (OFString *)percentEncodedUser
{
	OFString *old;

	if (percentEncodedUser != nil)
		OFURIVerifyIsEscaped(percentEncodedUser,
		    [OFCharacterSet URIUserAllowedCharacterSet], true);

	old = _percentEncodedUser;
	_percentEncodedUser = [percentEncodedUser copy];
	[old release];
}

- (void)setPassword: (OFString *)password
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedPassword;

	_percentEncodedPassword = [[password
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIPasswordAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedPassword: (OFString *)percentEncodedPassword
{
	OFString *old;

	if (percentEncodedPassword != nil)
		OFURIVerifyIsEscaped(percentEncodedPassword,
		    [OFCharacterSet URIPasswordAllowedCharacterSet], true);

	old = _percentEncodedPassword;
	_percentEncodedPassword = [percentEncodedPassword copy];
	[old release];
}

- (void)setPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedPath;

	_percentEncodedPath = [[path
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIPathAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedPath: (OFString *)percentEncodedPath
{
	OFString *old;

	OFURIVerifyIsEscaped(percentEncodedPath,
	    [OFCharacterSet URIPathAllowedCharacterSet], true);

	old = _percentEncodedPath;
	_percentEncodedPath = [percentEncodedPath copy];
	[old release];
}

- (void)setPathComponents: (OFArray *)components
{
	void *pool = objc_autoreleasePoolPush();

	if (components.count == 0)
		@throw [OFInvalidFormatException exception];

	if ([components.firstObject isEqual: @"/"]) {
		OFMutableArray *mutComponents =
		    [[components mutableCopy] autorelease];
		[mutComponents replaceObjectAtIndex: 0 withObject: @""];
		components = mutComponents;
	}

	self.path = [components componentsJoinedByString: @"/"];

	objc_autoreleasePoolPop(pool);
}

- (void)setQuery: (OFString *)query
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedQuery;

	_percentEncodedQuery = [[query
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIQueryAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedQuery: (OFString *)percentEncodedQuery
{
	OFString *old;

	if (percentEncodedQuery != nil)
		OFURIVerifyIsEscaped(percentEncodedQuery,
		    [OFCharacterSet URIQueryAllowedCharacterSet], true);

	old = _percentEncodedQuery;
	_percentEncodedQuery = [percentEncodedQuery copy];
	[old release];
}

- (void)setQueryItems:
    (OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *)
    queryItems
{
	void *pool;
	OFMutableString *percentEncodedQuery;
	OFCharacterSet *characterSet;
	OFString *old;

	if (queryItems == nil) {
		[_percentEncodedQuery release];
		_percentEncodedQuery = nil;
		return;
	}

	pool = objc_autoreleasePoolPush();
	percentEncodedQuery = [OFMutableString string];
	characterSet = [OFCharacterSet URIQueryKeyValueAllowedCharacterSet];

	for (OFPair OF_GENERIC(OFString *, OFString *) *item in queryItems) {
		OFString *key = [item.firstObject
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    characterSet];
		OFString *value = [item.secondObject
		    stringByAddingPercentEncodingWithAllowedCharacters:
		    characterSet];

		if (percentEncodedQuery.length > 0)
			[percentEncodedQuery appendString: @"&"];

		[percentEncodedQuery appendFormat: @"%@=%@", key, value];
	}

	old = _percentEncodedQuery;
	_percentEncodedQuery = [percentEncodedQuery copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setFragment: (OFString *)fragment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _percentEncodedFragment;

	_percentEncodedFragment = [[fragment
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIFragmentAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setPercentEncodedFragment: (OFString *)percentEncodedFragment
{
	OFString *old;

	if (percentEncodedFragment != nil)
		OFURIVerifyIsEscaped(percentEncodedFragment,
		    [OFCharacterSet URIFragmentAllowedCharacterSet], true);

	old = _percentEncodedFragment;
	_percentEncodedFragment = [percentEncodedFragment copy];
	[old release];
}

- (id)copy
{
	OFMutableURI *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)appendPathComponent: (OFString *)component
{
	[self appendPathComponent: component isDirectory: false];

#ifdef OF_HAVE_FILES
	if ([_scheme isEqual: @"file"] &&
	    ![_percentEncodedPath hasSuffix: @"/"] &&
	    [[OFFileManager defaultManager] directoryExistsAtURI: self]) {
		void *pool = objc_autoreleasePoolPush();
		OFString *path = [_percentEncodedPath
		    stringByAppendingString: @"/"];

		[_percentEncodedPath release];
		_percentEncodedPath = [path retain];

		objc_autoreleasePoolPop(pool);
	}
#endif
}

- (void)appendPathComponent: (OFString *)component
		isDirectory: (bool)isDirectory
{
	void *pool;
	OFString *path;

	if ([component isEqual: @"/"] && [_percentEncodedPath hasSuffix: @"/"])
		return;

	pool = objc_autoreleasePoolPush();
	component = [component
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    [OFCharacterSet URIPathAllowedCharacterSet]];

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([_percentEncodedPath hasSuffix: @"/"] ||
	    ([_scheme isEqual: @"file"] &&
	    [_percentEncodedPath hasSuffix: @":"]))
#else
	if ([_percentEncodedPath hasSuffix: @"/"])
#endif
		path = [_percentEncodedPath stringByAppendingString: component];
	else
		path = [_percentEncodedPath
		    stringByAppendingFormat: @"/%@", component];

	if (isDirectory && ![path hasSuffix: @"/"])
		path = [path stringByAppendingString: @"/"];

	[_percentEncodedPath release];
	_percentEncodedPath = [path retain];

	objc_autoreleasePoolPop(pool);
}

- (void)standardizePath
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFString *) *array;
	bool done = false, startsWithEmpty, endsWithEmpty;
	OFString *path;

	array = [[[_percentEncodedPath
	    componentsSeparatedByString: @"/"] mutableCopy] autorelease];

	endsWithEmpty = ([array.lastObject length] == 0);
	startsWithEmpty = ([array.firstObject length] == 0);

	while (!done) {
		size_t length = array.count;

		done = true;

		for (size_t i = 0; i < length; i++) {
			OFString *current = [array objectAtIndex: i];
			OFString *parent =
			    (i > 0 ? [array objectAtIndex: i - 1] : nil);

			if ([current isEqual: @"."] || current.length == 0) {
				[array removeObjectAtIndex: i];

				done = false;
				break;
			}

			if ([current isEqual: @".."] && parent != nil &&
			    ![parent isEqual: @".."]) {
				[array removeObjectsInRange:
				    OFMakeRange(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	if (startsWithEmpty)
		[array insertObject: @"" atIndex: 0];
	if (endsWithEmpty)
		[array addObject: @""];

	path = [array componentsJoinedByString: @"/"];
	if (startsWithEmpty && path.length == 0)
		path = @"/";

	self.percentEncodedPath = path;

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
	object_setClass(self, [OFURI class]);
}
@end
