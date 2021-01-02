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

#import "OFMutableURL.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
#endif
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

extern void of_url_verify_escaped(OFString *, OFCharacterSet *);

@implementation OFMutableURL
@dynamic scheme, URLEncodedScheme, host, URLEncodedHost, port, user;
@dynamic URLEncodedUser, password, URLEncodedPassword, path, URLEncodedPath;
@dynamic pathComponents, query, URLEncodedQuery, queryDictionary, fragment;
@dynamic URLEncodedFragment;

+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

- (void)setScheme: (OFString *)scheme
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedScheme;

	_URLEncodedScheme = [[scheme stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLSchemeAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedScheme: (OFString *)URLEncodedScheme
{
	OFString *old;

	if (URLEncodedScheme != nil)
		of_url_verify_escaped(URLEncodedScheme,
		    [OFCharacterSet URLSchemeAllowedCharacterSet]);

	old = _URLEncodedScheme;
	_URLEncodedScheme = [URLEncodedScheme copy];
	[old release];
}

- (void)setHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedHost;

	if (of_url_is_ipv6_host(host))
		_URLEncodedHost = [[OFString alloc]
		    initWithFormat: @"[%@]", host];
	else
		_URLEncodedHost = [[host
		    stringByURLEncodingWithAllowedCharacters:
		    [OFCharacterSet URLHostAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedHost: (OFString *)URLEncodedHost
{
	OFString *old;

	if ([URLEncodedHost hasPrefix: @"["] &&
	    [URLEncodedHost hasSuffix: @"]"]) {
		if (!of_url_is_ipv6_host([URLEncodedHost substringWithRange:
		    of_range(1, URLEncodedHost.length - 2)]))
			@throw [OFInvalidFormatException exception];
	} else if (URLEncodedHost != nil)
		of_url_verify_escaped(URLEncodedHost,
		    [OFCharacterSet URLHostAllowedCharacterSet]);

	old = _URLEncodedHost;
	_URLEncodedHost = [URLEncodedHost copy];
	[old release];
}

- (void)setPort: (OFNumber *)port
{
	OFNumber *old = _port;
	_port = [port copy];
	[old release];
}

- (void)setUser: (OFString *)user
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedUser;

	_URLEncodedUser = [[user stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLUserAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedUser: (OFString *)URLEncodedUser
{
	OFString *old;

	if (URLEncodedUser != nil)
		of_url_verify_escaped(URLEncodedUser,
		    [OFCharacterSet URLUserAllowedCharacterSet]);

	old = _URLEncodedUser;
	_URLEncodedUser = [URLEncodedUser copy];
	[old release];
}

- (void)setPassword: (OFString *)password
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedPassword;

	_URLEncodedPassword = [[password
	    stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLPasswordAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedPassword: (OFString *)URLEncodedPassword
{
	OFString *old;

	if (URLEncodedPassword != nil)
		of_url_verify_escaped(URLEncodedPassword,
		    [OFCharacterSet URLPasswordAllowedCharacterSet]);

	old = _URLEncodedPassword;
	_URLEncodedPassword = [URLEncodedPassword copy];
	[old release];
}

- (void)setPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedPath;

	_URLEncodedPath = [[path stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLPathAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedPath: (OFString *)URLEncodedPath
{
	OFString *old;

	if (URLEncodedPath != nil)
		of_url_verify_escaped(URLEncodedPath,
		    [OFCharacterSet URLPathAllowedCharacterSet]);

	old = _URLEncodedPath;
	_URLEncodedPath = [URLEncodedPath copy];
	[old release];
}

- (void)setPathComponents: (OFArray *)components
{
	void *pool = objc_autoreleasePoolPush();

	if (components == nil) {
		self.path = nil;
		return;
	}

	if (components.count == 0)
		@throw [OFInvalidFormatException exception];

	if ([components.firstObject length] != 0)
		@throw [OFInvalidFormatException exception];

	self.path = [components componentsJoinedByString: @"/"];

	objc_autoreleasePoolPop(pool);
}

- (void)setQuery: (OFString *)query
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedQuery;

	_URLEncodedQuery = [[query stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLQueryAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedQuery: (OFString *)URLEncodedQuery
{
	OFString *old;

	if (URLEncodedQuery != nil)
		of_url_verify_escaped(URLEncodedQuery,
		    [OFCharacterSet URLQueryAllowedCharacterSet]);

	old = _URLEncodedQuery;
	_URLEncodedQuery = [URLEncodedQuery copy];
	[old release];
}

- (void)setQueryDictionary:
    (OFDictionary OF_GENERIC(OFString *, OFString *) *)dictionary
{
	void *pool;
	OFMutableString *URLEncodedQuery;
	OFEnumerator OF_GENERIC(OFString *) *keyEnumerator, *objectEnumerator;
	OFCharacterSet *characterSet;
	OFString *key, *object, *old;

	if (dictionary == nil) {
		[_URLEncodedQuery release];
		_URLEncodedQuery = nil;
		return;
	}

	pool = objc_autoreleasePoolPush();
	URLEncodedQuery = [OFMutableString string];
	keyEnumerator = [dictionary keyEnumerator];
	objectEnumerator = [dictionary objectEnumerator];
	characterSet = [OFCharacterSet URLQueryKeyValueAllowedCharacterSet];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		key = [key
		    stringByURLEncodingWithAllowedCharacters: characterSet];
		object = [object
		    stringByURLEncodingWithAllowedCharacters: characterSet];

		if (URLEncodedQuery.length > 0)
			[URLEncodedQuery appendString: @"&"];

		[URLEncodedQuery appendFormat: @"%@=%@", key, object];
	}

	old = _URLEncodedQuery;
	_URLEncodedQuery = [URLEncodedQuery copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setFragment: (OFString *)fragment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old = _URLEncodedFragment;

	_URLEncodedFragment = [[fragment
	    stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLFragmentAllowedCharacterSet]] copy];

	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setURLEncodedFragment: (OFString *)URLEncodedFragment
{
	OFString *old;

	if (URLEncodedFragment != nil)
		of_url_verify_escaped(URLEncodedFragment,
		    [OFCharacterSet URLFragmentAllowedCharacterSet]);

	old = _URLEncodedFragment;
	_URLEncodedFragment = [URLEncodedFragment copy];
	[old release];
}

- (id)copy
{
	OFMutableURL *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)appendPathComponent: (OFString *)component
{
	[self appendPathComponent: component
		      isDirectory: false];

#ifdef OF_HAVE_FILES
	if ([_URLEncodedScheme isEqual: @"file"] &&
	    ![_URLEncodedPath hasSuffix: @"/"] &&
	    [[OFFileManager defaultManager] directoryExistsAtURL: self]) {
		void *pool = objc_autoreleasePoolPush();
		OFString *path = [_URLEncodedPath
		    stringByAppendingString: @"/"];

		[_URLEncodedPath release];
		_URLEncodedPath = [path retain];

		objc_autoreleasePoolPop(pool);
	}
#endif
}

- (void)appendPathComponent: (OFString *)component
		isDirectory: (bool)isDirectory
{
	void *pool;
	OFString *path;

	if ([component isEqual: @"/"] && [_URLEncodedPath hasSuffix: @"/"])
		return;

	pool = objc_autoreleasePoolPush();
	component = [component stringByURLEncodingWithAllowedCharacters:
	    [OFCharacterSet URLPathAllowedCharacterSet]];

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([_URLEncodedPath hasSuffix: @"/"] ||
	    ([_URLEncodedScheme isEqual: @"file"] &&
	    [_URLEncodedPath hasSuffix: @":"]))
#else
	if ([_URLEncodedPath hasSuffix: @"/"])
#endif
		path = [_URLEncodedPath stringByAppendingString: component];
	else
		path = [_URLEncodedPath
		    stringByAppendingFormat: @"/%@", component];

	if (isDirectory && ![path hasSuffix: @"/"])
		path = [path stringByAppendingString: @"/"];

	[_URLEncodedPath release];
	_URLEncodedPath = [path retain];

	objc_autoreleasePoolPop(pool);
}

- (void)standardizePath
{
	void *pool;
	OFMutableArray OF_GENERIC(OFString *) *array;
	bool done = false, endsWithEmpty;
	OFString *path;

	if (_URLEncodedPath == nil)
		return;

	pool = objc_autoreleasePoolPush();

	array = [[[_URLEncodedPath
	    componentsSeparatedByString: @"/"] mutableCopy] autorelease];

	if ([array.firstObject length] != 0)
		@throw [OFInvalidFormatException exception];

	endsWithEmpty = ([array.lastObject length] == 0);

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
				    of_range(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	[array insertObject: @""
		    atIndex: 0];
	if (endsWithEmpty)
		[array addObject: @""];

	path = [array componentsJoinedByString: @"/"];
	if (path.length == 0)
		path = @"/";

	[self setURLEncodedPath: path];

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
	object_setClass(self, [OFURL class]);
}
@end
