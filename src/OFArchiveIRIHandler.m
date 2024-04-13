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

#include <errno.h>

#import "OFArchiveIRIHandler.h"
#import "OFCharacterSet.h"
#import "OFGZIPStream.h"
#import "OFIRI.h"
#import "OFLHAArchive.h"
#import "OFStream.h"
#import "OFTarArchive.h"
#import "OFZIPArchive.h"
#import "OFZooArchive.h"

#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"

@interface OFArchiveIRIHandlerPathAllowedCharacterSet: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, OFUnichar);
}
@end

static OFCharacterSet *pathAllowedCharacters;

static void
initPathAllowedCharacters(void)
{
	pathAllowedCharacters =
	    [[OFArchiveIRIHandlerPathAllowedCharacterSet alloc] init];
}

@implementation OFArchiveIRIHandler
- (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFString *scheme = IRI.scheme;
	OFString *percentEncodedPath, *path;
	size_t pos;
	OFIRI *archiveIRI;
	OFStream *stream;

	if (IRI.host != nil || IRI.port != nil || IRI.user != nil ||
	    IRI.password != nil || IRI.query != nil || IRI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		/*
		 * Writing has some implications that are not decided yet: Will
		 * it always append to an archive? What happens if the file
		 * already exists?
		 */
		@throw [OFInvalidArgumentException exception];

	/*
	 * GZIP only compresses one file and thus has no path inside an
	 * archive.
	 */
	if ([scheme isEqual: @"gzip"]) {
		stream = [OFIRIHandler openItemAtIRI: [OFIRI IRIWithString:
							  IRI.path]
						mode: mode];
		stream = [OFGZIPStream streamWithStream: stream mode: mode];
		goto end;
	}

	percentEncodedPath = IRI.percentEncodedPath;
	pos = [percentEncodedPath
	    rangeOfString: @"!"
		  options: OFStringSearchBackwards].location;

	if (pos == OFNotFound)
		@throw [OFInvalidArgumentException exception];

	archiveIRI = [OFIRI IRIWithString:
	    [percentEncodedPath substringWithRange: OFMakeRange(0, pos)]
	    .stringByRemovingPercentEncoding];
	path = [percentEncodedPath substringWithRange:
	    OFMakeRange(pos + 1, percentEncodedPath.length - pos - 1)]
	    .stringByRemovingPercentEncoding;

	if ([scheme isEqual: @"lha"]) {
		OFLHAArchive *archive = [OFLHAArchive archiveWithIRI: archiveIRI
								mode: mode];
		OFLHAArchiveEntry *entry;

		while ((entry = [archive nextEntry]) != nil) {
			if ([entry.fileName isEqual: path]) {
				stream = [archive streamForReadingCurrentEntry];
				goto end;
			}
		}

		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: ENOENT];
	} else if ([scheme isEqual: @"tar"]) {
		OFTarArchive *archive = [OFTarArchive archiveWithIRI: archiveIRI
								mode: mode];
		OFTarArchiveEntry *entry;

		while ((entry = [archive nextEntry]) != nil) {
			if ([entry.fileName isEqual: path]) {
				stream = [archive streamForReadingCurrentEntry];
				goto end;
			}
		}

		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: ENOENT];
	} else if ([scheme isEqual: @"zip"]) {
		OFZIPArchive *archive = [OFZIPArchive archiveWithIRI: archiveIRI
								mode: mode];

		stream = [archive streamForReadingFile: path];
	} else if ([scheme isEqual: @"zoo"]) {
		OFZooArchive *archive = [OFZooArchive archiveWithIRI: archiveIRI
								mode: mode];
		OFZooArchiveEntry *entry;

		while ((entry = [archive nextEntry]) != nil) {
			if ([entry.fileName isEqual: path]) {
				stream = [archive streamForReadingCurrentEntry];
				goto end;
			}
		}

		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: ENOENT];
	} else
		@throw [OFInvalidArgumentException exception];

end:
	stream = [stream retain];

	objc_autoreleasePoolPop(pool);

	return [stream autorelease];
}
@end

@implementation OFArchiveIRIHandlerPathAllowedCharacterSet
- (instancetype)init
{
	self = [super init];

	@try {
		_characterSet =
		    [[OFCharacterSet IRIPathAllowedCharacterSet] retain];
		_characterIsMember = (bool (*)(id, SEL, OFUnichar))
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

- (bool)characterIsMember: (OFUnichar)character
{
	return (character != '!' && _characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end

OFIRI *
OFArchiveIRIHandlerIRIForFileInArchive(OFString *scheme,
    OFString *pathInArchive, OFIRI *archiveIRI)
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFMutableIRI *ret = [OFMutableIRI IRIWithScheme: scheme];
	void *pool = objc_autoreleasePoolPush();

	OFOnce(&onceControl, initPathAllowedCharacters);

	pathInArchive = [pathInArchive
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];

	ret.percentEncodedPath = [OFString
	    stringWithFormat: @"%@!%@", archiveIRI.string, pathInArchive];
	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}
