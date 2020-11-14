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

#include <stdlib.h>
#include <string.h>

#import "OFURL.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
# import "OFFileURLHandler.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

#import "once.h"

@interface OFURLAllowedCharacterSetBase: OFCharacterSet
@end

@interface OFURLAllowedCharacterSet: OFURLAllowedCharacterSetBase
@end

@interface OFURLSchemeAllowedCharacterSet: OFURLAllowedCharacterSetBase
@end

@interface OFURLPathAllowedCharacterSet: OFURLAllowedCharacterSetBase
@end

@interface OFURLQueryOrFragmentAllowedCharacterSet: OFURLAllowedCharacterSetBase
@end

@interface OFURLQueryKeyValueAllowedCharacterSet: OFURLAllowedCharacterSetBase
@end

static OFCharacterSet *URLAllowedCharacterSet = nil;
static OFCharacterSet *URLSchemeAllowedCharacterSet = nil;
static OFCharacterSet *URLPathAllowedCharacterSet = nil;
static OFCharacterSet *URLQueryOrFragmentAllowedCharacterSet = nil;
static OFCharacterSet *URLQueryKeyValueAllowedCharacterSet = nil;

static of_once_t URLAllowedCharacterSetOnce = OF_ONCE_INIT;
static of_once_t URLQueryOrFragmentAllowedCharacterSetOnce = OF_ONCE_INIT;

static void
initURLAllowedCharacterSet(void)
{
	URLAllowedCharacterSet = [[OFURLAllowedCharacterSet alloc] init];
}

static void
initURLSchemeAllowedCharacterSet(void)
{
	URLSchemeAllowedCharacterSet =
	    [[OFURLSchemeAllowedCharacterSet alloc] init];
}

static void
initURLPathAllowedCharacterSet(void)
{
	URLPathAllowedCharacterSet =
	    [[OFURLPathAllowedCharacterSet alloc] init];
}

static void
initURLQueryOrFragmentAllowedCharacterSet(void)
{
	URLQueryOrFragmentAllowedCharacterSet =
	    [[OFURLQueryOrFragmentAllowedCharacterSet alloc] init];
}

static void
initURLQueryKeyValueAllowedCharacterSet(void)
{
	URLQueryKeyValueAllowedCharacterSet =
	    [[OFURLQueryKeyValueAllowedCharacterSet alloc] init];
}

OF_DIRECT_MEMBERS
@interface OFInvertedCharacterSetWithoutPercent: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, of_unichar_t);
}

- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet;
@end

bool
of_url_is_ipv6_host(OFString *host)
{
	const char *UTF8String = host.UTF8String;
	bool hasColon = false;

	while (*UTF8String != '\0') {
		if (!of_ascii_isdigit(*UTF8String) && *UTF8String != ':' &&
		    (*UTF8String < 'a' || *UTF8String > 'f') &&
		    (*UTF8String < 'A' || *UTF8String > 'F'))
			return false;

		if (*UTF8String == ':')
			hasColon = true;

		UTF8String++;
	}

	return hasColon;
}

@implementation OFURLAllowedCharacterSetBase
- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}
@end

@implementation OFURLAllowedCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURLSchemeAllowedCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '+':
	case '-':
	case '.':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURLPathAllowedCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURLQueryOrFragmentAllowedCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFURLQueryKeyValueAllowedCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case ':':
	case '@':
	case '/':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFInvertedCharacterSetWithoutPercent
- (instancetype)initWithCharacterSet: (OFCharacterSet *)characterSet
{
	self = [super init];

	@try {
		_characterSet = [characterSet retain];
		_characterIsMember = (bool (*)(id, SEL, of_unichar_t))
		    [_characterSet methodForSelector:
		    @selector(characterIsMember:)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (of_unichar_t)character
{
	return (character != '%' && !_characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end

void
of_url_verify_escaped(OFString *string, OFCharacterSet *characterSet)
{
	void *pool = objc_autoreleasePoolPush();

	characterSet = [[[OFInvertedCharacterSetWithoutPercent alloc]
	    initWithCharacterSet: characterSet] autorelease];

	if ([string indexOfCharacterFromSet: characterSet] != OF_NOT_FOUND)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);
}

@implementation OFCharacterSet (URLCharacterSets)
+ (OFCharacterSet *)URLSchemeAllowedCharacterSet
{
	static of_once_t onceControl = OF_ONCE_INIT;
	of_once(&onceControl, initURLSchemeAllowedCharacterSet);

	return URLSchemeAllowedCharacterSet;
}

+ (OFCharacterSet *)URLHostAllowedCharacterSet
{
	of_once(&URLAllowedCharacterSetOnce, initURLAllowedCharacterSet);

	return URLAllowedCharacterSet;
}

+ (OFCharacterSet *)URLUserAllowedCharacterSet
{
	of_once(&URLAllowedCharacterSetOnce, initURLAllowedCharacterSet);

	return URLAllowedCharacterSet;
}

+ (OFCharacterSet *)URLPasswordAllowedCharacterSet
{
	of_once(&URLAllowedCharacterSetOnce, initURLAllowedCharacterSet);

	return URLAllowedCharacterSet;
}

+ (OFCharacterSet *)URLPathAllowedCharacterSet
{
	static of_once_t onceControl = OF_ONCE_INIT;
	of_once(&onceControl, initURLPathAllowedCharacterSet);

	return URLPathAllowedCharacterSet;
}

+ (OFCharacterSet *)URLQueryAllowedCharacterSet
{
	of_once(&URLQueryOrFragmentAllowedCharacterSetOnce,
	    initURLQueryOrFragmentAllowedCharacterSet);

	return URLQueryOrFragmentAllowedCharacterSet;
}

+ (OFCharacterSet *)URLQueryKeyValueAllowedCharacterSet
{
	static of_once_t onceControl = OF_ONCE_INIT;
	of_once(&onceControl, initURLQueryKeyValueAllowedCharacterSet);

	return URLQueryKeyValueAllowedCharacterSet;
}

+ (OFCharacterSet *)URLFragmentAllowedCharacterSet
{
	of_once(&URLQueryOrFragmentAllowedCharacterSetOnce,
	    initURLQueryOrFragmentAllowedCharacterSet);

	return URLQueryOrFragmentAllowedCharacterSet;
}
@end

@implementation OFURL
+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
		relativeToURL: (OFURL *)URL
{
	return [[[self alloc] initWithString: string
			       relativeToURL: URL] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)fileURLWithPath: (OFString *)path
{
	return [[[self alloc] initFileURLWithPath: path] autorelease];
}

+ (instancetype)fileURLWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory
{
	return [[[self alloc] initFileURLWithPath: path
				      isDirectory: isDirectory] autorelease];
}
#endif

- (instancetype)initWithString: (OFString *)string
{
	char *UTF8String, *UTF8String2 = NULL;

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp, *tmp2;
		bool isIPv6Host = false;

		if ((UTF8String2 = of_strdup(string.UTF8String)) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     string.UTF8StringLength];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, ':')) == NULL)
			@throw [OFInvalidFormatException exception];

		if (strncmp(tmp, "://", 3) != 0)
			@throw [OFInvalidFormatException exception];

		for (tmp2 = UTF8String; tmp2 < tmp; tmp2++)
			*tmp2 = of_ascii_tolower(*tmp2);

		_URLEncodedScheme = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: tmp - UTF8String];

		of_url_verify_escaped(_URLEncodedScheme,
		    [OFCharacterSet URLSchemeAllowedCharacterSet]);

		UTF8String = tmp + 3;

		if ((tmp = strchr(UTF8String, '/')) != NULL) {
			*tmp = '\0';
			tmp++;
		}

		if ((tmp2 = strchr(UTF8String, '@')) != NULL) {
			char *tmp3;

			*tmp2 = '\0';
			tmp2++;

			if ((tmp3 = strchr(UTF8String, ':')) != NULL) {
				*tmp3 = '\0';
				tmp3++;

				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];
				_URLEncodedPassword = [[OFString alloc]
				    initWithUTF8String: tmp3];

				of_url_verify_escaped(_URLEncodedPassword,
				    [OFCharacterSet
				    URLPasswordAllowedCharacterSet]);
			} else
				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];

			of_url_verify_escaped(_URLEncodedUser,
			    [OFCharacterSet URLUserAllowedCharacterSet]);

			UTF8String = tmp2;
		}

		if (UTF8String[0] == '[') {
			tmp2 = UTF8String++;

			while (of_ascii_isdigit(*UTF8String) ||
			    *UTF8String == ':' ||
			    (*UTF8String >= 'a' && *UTF8String <= 'f') ||
			    (*UTF8String >= 'A' && *UTF8String <= 'F'))
				UTF8String++;

			if (*UTF8String != ']')
				@throw [OFInvalidFormatException exception];

			UTF8String++;

			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: tmp2
					length: UTF8String - tmp2];

			if (*UTF8String == ':') {
				OFString *portString;

				tmp2 = ++UTF8String;

				while (*UTF8String != '\0') {
					if (!of_ascii_isdigit(*UTF8String))
						@throw [OFInvalidFormatException
						    exception];

					UTF8String++;
				}

				portString = [OFString
				    stringWithUTF8String: tmp2
						  length: UTF8String - tmp2];

				if (portString.length == 0 ||
				    portString.unsignedLongLongValue > 65535)
					@throw [OFInvalidFormatException
					    exception];

				_port = [[OFNumber alloc] initWithUnsignedShort:
				    portString.unsignedLongLongValue];
			} else if (*UTF8String != '\0')
				@throw [OFInvalidFormatException exception];

			isIPv6Host = true;
		} else if ((tmp2 = strchr(UTF8String, ':')) != NULL) {
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			portString = [OFString stringWithUTF8String: tmp2];

			if (portString.unsignedLongLongValue > 65535)
				@throw [OFInvalidFormatException exception];

			_port = [[OFNumber alloc] initWithUnsignedShort:
			    portString.unsignedLongLongValue];
		} else
			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

		if (!isIPv6Host)
			of_url_verify_escaped(_URLEncodedHost,
			    [OFCharacterSet URLHostAllowedCharacterSet]);

		if ((UTF8String = tmp) != NULL) {
			if ((tmp = strchr(UTF8String, '#')) != NULL) {
				*tmp = '\0';

				_URLEncodedFragment = [[OFString alloc]
				    initWithUTF8String: tmp + 1];

				of_url_verify_escaped(_URLEncodedFragment,
				    [OFCharacterSet
				    URLFragmentAllowedCharacterSet]);
			}

			if ((tmp = strchr(UTF8String, '?')) != NULL) {
				*tmp = '\0';

				_URLEncodedQuery = [[OFString alloc]
				    initWithUTF8String: tmp + 1];

				of_url_verify_escaped(_URLEncodedQuery,
				    [OFCharacterSet
				    URLQueryAllowedCharacterSet]);
			}

			UTF8String--;
			*UTF8String = '/';

			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			of_url_verify_escaped(_URLEncodedPath,
			    [OFCharacterSet URLPathAllowedCharacterSet]);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

- (instancetype)initWithString: (OFString *)string
		 relativeToURL: (OFURL *)URL
{
	char *UTF8String, *UTF8String2 = NULL;

	if ([string containsString: @"://"])
		return [self initWithString: string];

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp;

		_URLEncodedScheme = [URL->_URLEncodedScheme copy];
		_URLEncodedHost = [URL->_URLEncodedHost copy];
		_port = [URL->_port copy];
		_URLEncodedUser = [URL->_URLEncodedUser copy];
		_URLEncodedPassword = [URL->_URLEncodedPassword copy];

		if ((UTF8String2 = of_strdup(string.UTF8String)) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     string.UTF8StringLength];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_URLEncodedFragment = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			of_url_verify_escaped(_URLEncodedFragment,
			    [OFCharacterSet URLFragmentAllowedCharacterSet]);
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_URLEncodedQuery = [[OFString alloc]
			    initWithUTF8String: tmp + 1];

			of_url_verify_escaped(_URLEncodedQuery,
			    [OFCharacterSet URLQueryAllowedCharacterSet]);
		}

		if (*UTF8String == '/')
			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		else {
			OFString *relativePath =
			    [OFString stringWithUTF8String: UTF8String];

			if ([URL->_URLEncodedPath hasSuffix: @"/"])
				_URLEncodedPath = [[URL->_URLEncodedPath
				    stringByAppendingString: relativePath]
				    copy];
			else {
				OFMutableString *path = [OFMutableString
				    stringWithString:
				    (URL->_URLEncodedPath != nil
				    ? URL->_URLEncodedPath
				    : @"/")];
				of_range_t range = [path
				    rangeOfString: @"/"
					  options: OF_STRING_SEARCH_BACKWARDS];

				if (range.location == OF_NOT_FOUND)
					@throw [OFInvalidFormatException
					    exception];

				range.location++;
				range.length = path.length - range.location;

				[path replaceCharactersInRange: range
						    withString: relativePath];
				[path makeImmutable];

				_URLEncodedPath = [path copy];
			}
		}

		of_url_verify_escaped(_URLEncodedPath,
		    [OFCharacterSet URLPathAllowedCharacterSet]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initFileURLWithPath: (OFString *)path
{
	bool isDirectory;

	@try {
		void *pool = objc_autoreleasePoolPush();

		isDirectory = [path of_isDirectoryPath];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initFileURLWithPath: path
			     isDirectory: isDirectory];

	return self;
}

- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *URLEncodedHost = nil;

		if (!path.absolutePath) {
			OFString *currentDirectoryPath = [OFFileManager
			    defaultManager].currentDirectoryPath;

			path = [currentDirectoryPath
			    stringByAppendingPathComponent: path];
			path = path.stringByStandardizingPath;
		}

		path = [path
		    of_pathToURLPathWithURLEncodedHost: &URLEncodedHost];
		_URLEncodedHost = [URLEncodedHost copy];

		if (isDirectory && ![path hasSuffix: @"/"])
			path = [path stringByAppendingString: @"/"];

		_URLEncodedScheme = @"file";
		_URLEncodedPath = [[path
		    stringByURLEncodingWithAllowedCharacters:
		    [OFCharacterSet URLPathAllowedCharacterSet]] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	void *pool = objc_autoreleasePoolPush();
	OFString *stringValue;

	@try {
		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		stringValue = element.stringValue;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithString: stringValue];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (void)dealloc
{
	[_URLEncodedScheme release];
	[_URLEncodedHost release];
	[_port release];
	[_URLEncodedUser release];
	[_URLEncodedPassword release];
	[_URLEncodedPath release];
	[_URLEncodedQuery release];
	[_URLEncodedFragment release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFURL *URL;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFURL class]])
		return false;

	URL = object;

	if (URL->_URLEncodedScheme != _URLEncodedScheme &&
	    ![URL->_URLEncodedScheme isEqual: _URLEncodedScheme])
		return false;
	if (URL->_URLEncodedHost != _URLEncodedHost &&
	    ![URL->_URLEncodedHost isEqual: _URLEncodedHost])
		return false;
	if (URL->_port != _port && ![URL->_port isEqual: _port])
		return false;
	if (URL->_URLEncodedUser != _URLEncodedUser &&
	    ![URL->_URLEncodedUser isEqual: _URLEncodedUser])
		return false;
	if (URL->_URLEncodedPassword != _URLEncodedPassword &&
	    ![URL->_URLEncodedPassword isEqual: _URLEncodedPassword])
		return false;
	if (URL->_URLEncodedPath != _URLEncodedPath &&
	    ![URL->_URLEncodedPath isEqual: _URLEncodedPath])
		return false;
	if (URL->_URLEncodedQuery != _URLEncodedQuery &&
	    ![URL->_URLEncodedQuery isEqual: _URLEncodedQuery])
		return false;
	if (URL->_URLEncodedFragment != _URLEncodedFragment &&
	    ![URL->_URLEncodedFragment isEqual: _URLEncodedFragment])
		return false;

	return true;
}

- (unsigned long)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _URLEncodedScheme.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedHost.hash);
	OF_HASH_ADD_HASH(hash, _port.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedUser.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedPassword.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedPath.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedQuery.hash);
	OF_HASH_ADD_HASH(hash, _URLEncodedFragment.hash);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)scheme
{
	return _URLEncodedScheme.stringByURLDecoding;
}

- (OFString *)URLEncodedScheme
{
	return _URLEncodedScheme;
}

- (OFString *)host
{
	if ([_URLEncodedHost hasPrefix: @"["] &&
	    [_URLEncodedHost hasSuffix: @"]"]) {
		OFString *host = [_URLEncodedHost substringWithRange:
		    of_range(1, _URLEncodedHost.length - 2)];

		if (!of_url_is_ipv6_host(host))
			@throw [OFInvalidArgumentException exception];

		return host;
	}

	return _URLEncodedHost.stringByURLDecoding;
}

- (OFString *)URLEncodedHost
{
	return _URLEncodedHost;
}

- (OFNumber *)port
{
	return _port;
}

- (OFString *)user
{
	return _URLEncodedUser.stringByURLDecoding;
}

- (OFString *)URLEncodedUser
{
	return _URLEncodedUser;
}

- (OFString *)password
{
	return _URLEncodedPassword.stringByURLDecoding;
}

- (OFString *)URLEncodedPassword
{
	return _URLEncodedPassword;
}

- (OFString *)path
{
	return _URLEncodedPath.stringByURLDecoding;
}

- (OFString *)URLEncodedPath
{
	return _URLEncodedPath;
}

- (OFArray *)pathComponents
{
	void *pool = objc_autoreleasePoolPush();
#ifdef OF_HAVE_FILES
	bool isFile = [_URLEncodedScheme isEqual: @"file"];
#endif
	OFMutableArray *ret;
	size_t count;

#ifdef OF_HAVE_FILES
	if (isFile) {
		OFString *path = [_URLEncodedPath
		    of_URLPathToPathWithURLEncodedHost: nil];
		ret = [[path.pathComponents mutableCopy] autorelease];

		if (![ret.firstObject isEqual: @"/"])
			    [ret insertObject: @"/"
				      atIndex: 0];
	} else
#endif
		ret = [[[_URLEncodedPath componentsSeparatedByString: @"/"]
		    mutableCopy] autorelease];

	count = ret.count;

	if (count > 0 && [ret.firstObject length] == 0)
		[ret replaceObjectAtIndex: 0
			       withObject: @"/"];

	for (size_t i = 0; i < count; i++) {
		OFString *component = [ret objectAtIndex: i];

#ifdef OF_HAVE_FILES
		if (isFile)
			component =
			    [component of_pathComponentToURLPathComponent];
#endif

		[ret replaceObjectAtIndex: i
			       withObject: component.stringByURLDecoding];
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)lastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = _URLEncodedPath;
	const char *UTF8String, *lastComponent;
	size_t length;
	OFString *ret;

	if (path == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if ([path isEqual: @"/"]) {
		objc_autoreleasePoolPop(pool);
		return @"/";
	}

	if ([path hasSuffix: @"/"])
		path = [path substringToIndex: path.length - 1];

	UTF8String = lastComponent = path.UTF8String;
	length = path.UTF8StringLength;

	for (size_t i = 1; i <= length; i++) {
		if (UTF8String[length - i] == '/') {
			lastComponent = UTF8String + (length - i) + 1;
			break;
		}
	}

	ret = [OFString
	    stringWithUTF8String: lastComponent
			  length: length - (lastComponent - UTF8String)];
	ret = [ret.stringByURLDecoding retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)query
{
	return _URLEncodedQuery.stringByURLDecoding;
}

- (OFString *)URLEncodedQuery
{
	return _URLEncodedQuery;
}

- (OFDictionary OF_GENERIC(OFString *, OFString *) *)queryDictionary
{
	void *pool;
	OFArray OF_GENERIC(OFString *) *pairs;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *ret;

	if (_URLEncodedQuery == nil)
		return nil;

	pool = objc_autoreleasePoolPush();
	pairs = [_URLEncodedQuery componentsSeparatedByString: @"&"];
	ret = [OFMutableDictionary dictionaryWithCapacity: pairs.count];

	for (OFString *pair in pairs) {
		OFArray *parts = [pair componentsSeparatedByString: @"="];

		if (parts.count != 2)
			@throw [OFInvalidFormatException exception];

		[ret setObject: [[parts objectAtIndex: 1] stringByURLDecoding]
			forKey: [[parts objectAtIndex: 0] stringByURLDecoding]];
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)fragment
{
	return _URLEncodedFragment.stringByURLDecoding;
}

- (OFString *)URLEncodedFragment
{
	return _URLEncodedFragment;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFURL *copy = [[OFMutableURL alloc] init];

	@try {
		copy->_URLEncodedScheme = [_URLEncodedScheme copy];
		copy->_URLEncodedHost = [_URLEncodedHost copy];
		copy->_port = [_port copy];
		copy->_URLEncodedUser = [_URLEncodedUser copy];
		copy->_URLEncodedPassword = [_URLEncodedPassword copy];
		copy->_URLEncodedPath = [_URLEncodedPath copy];
		copy->_URLEncodedQuery = [_URLEncodedQuery copy];
		copy->_URLEncodedFragment = [_URLEncodedFragment copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)string
{
	OFMutableString *ret = [OFMutableString string];

	[ret appendFormat: @"%@://", _URLEncodedScheme];

	if (_URLEncodedUser != nil && _URLEncodedPassword != nil)
		[ret appendFormat: @"%@:%@@",
				   _URLEncodedUser, _URLEncodedPassword];
	else if (_URLEncodedUser != nil)
		[ret appendFormat: @"%@@", _URLEncodedUser];

	if (_URLEncodedHost != nil)
		[ret appendString: _URLEncodedHost];
	if (_port != nil)
		[ret appendFormat: @":%@", _port];

	if (_URLEncodedPath != nil) {
		if (![_URLEncodedPath hasPrefix: @"/"])
			@throw [OFInvalidFormatException exception];

		[ret appendString: _URLEncodedPath];
	}

	if (_URLEncodedQuery != nil)
		[ret appendFormat: @"?%@", _URLEncodedQuery];

	if (_URLEncodedFragment != nil)
		[ret appendFormat: @"#%@", _URLEncodedFragment];

	[ret makeImmutable];

	return ret;
}

#ifdef OF_HAVE_FILES
- (OFString *)fileSystemRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (![_URLEncodedScheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_URLEncodedPath hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = [self.path of_URLPathToPathWithURLEncodedHost: _URLEncodedHost];

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}
#endif

- (OFURL *)URLByAppendingPathComponent: (OFString *)component
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL appendPathComponent: component];
	[URL makeImmutable];

	return URL;
}

- (OFURL *)URLByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL appendPathComponent: component
		     isDirectory: isDirectory];
	[URL makeImmutable];

	return URL;
}

- (OFURL *)URLByStandardizingPath
{
	OFMutableURL *URL = [[self mutableCopy] autorelease];

	[URL standardizePath];
	[URL makeImmutable];

	return URL;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   self.class, self.string];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self.string];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}
@end
