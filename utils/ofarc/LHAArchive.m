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

#import "OFApplication.h"
#import "OFDate.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "LHAArchive.h"
#import "OFArc.h"

static OFArc *app;

static OFString *
indent(OFString *string)
{
	return [string stringByReplacingOccurrencesOfString: @"\n"
						 withString: @"\n\t"];
}

static void
setPermissions(OFString *path, OFLHAArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFNumber *mode = entry.mode;

	if (mode == nil)
		return;

	mode = [OFNumber numberWithUnsignedShort:
	    mode.unsignedShortValue & 0777];

	of_file_attributes_t attributes = [OFDictionary
	    dictionaryWithObject: mode
			  forKey: of_file_attribute_key_posix_permissions];

	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
#endif
}

static void
setModificationDate(OFString *path, OFLHAArchiveEntry *entry)
{
	OFDate *modificationDate = entry.modificationDate;
	of_file_attributes_t attributes;

	if (modificationDate == nil) {
		/*
		 * Fall back to the original date if we have no modification
		 * date, as the modification date is a UNIX extension.
		 */
		modificationDate = entry.date;

		if (modificationDate == nil)
			return;
	}

	attributes = [OFDictionary
	    dictionaryWithObject: modificationDate
			  forKey: of_file_attribute_key_modification_date];
	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
}

@implementation LHAArchive
+ (void)initialize
{
	if (self == [LHAArchive class])
		app = (OFArc *)[OFApplication sharedApplication].delegate;
}

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode
			 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithStream: stream
					mode: mode
				    encoding: encoding] autorelease];
}

- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (of_string_encoding_t)encoding
{
	self = [super init];

	@try {
		_archive = [[OFLHAArchive alloc] initWithStream: stream
							   mode: mode];

		if (encoding != OF_STRING_ENCODING_AUTODETECT)
			_archive.encoding = encoding;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_archive release];

	[super dealloc];
}

- (void)listFiles
{
	OFLHAArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[of_stdout writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *date = [entry.date
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
			OFString *compressedSize = [OFString stringWithFormat:
			    @"%" PRIu32, entry.compressedSize];
			OFString *uncompressedSize = [OFString stringWithFormat:
			    @"%" PRIu32, entry.uncompressedSize];
			OFString *CRC16 = [OFString stringWithFormat:
			    @"%04" PRIX16, entry.CRC16];

			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_compressed_size",
			    @"["
			    @"    'Compressed: ',"
			    @"    ["
			    @"        {'size == 1': '1 byte'},"
			    @"        {'': '%[size] bytes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"size", compressedSize)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_uncompressed_size",
			    @"["
			    @"    'Uncompressed: ',"
			    @"    ["
			    @"        {'size == 1': '1 byte'},"
			    @"        {'': '%[size] bytes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"size", uncompressedSize)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_compression_method",
			    @"Compression method: %[method]",
			    @"method", entry.compressionMethod)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(@"list_crc16",
			    @"CRC16: %[crc16]",
			    @"crc16", CRC16)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(@"list_date",
			    @"Date: %[date]",
			    @"date", date)];

			if (entry.mode != nil) {
				OFString *modeString = [OFString
				    stringWithFormat:
				    @"%ho", entry.mode.unsignedShortValue];

				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(@"list_mode",
				    @"Mode: %[mode]",
				    @"mode", modeString)];
			}
			if (entry.UID != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(@"list_uid",
				    @"UID: %[uid]",
				    @"uid", entry.UID)];
			}
			if (entry.GID != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(@"list_gid",
				    @"GID: %[gid]",
				    @"gid", entry.GID)];
			}
			if (entry.owner != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_owner",
				    @"Owner: %[owner]",
				    @"owner", entry.owner)];
			}
			if (entry.group != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_group",
				    @"Group: %[group]",
				    @"group", entry.group)];
			}

			if (app->_outputLevel >= 2) {
				OFString *headerLevel = [OFString
				    stringWithFormat: @"%" PRIu8,
						      entry.headerLevel];

				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_header_level",
				    @"Header level: %[level]",
				    @"level", headerLevel)];

				if (entry.operatingSystemIdentifier != '\0') {
					OFString *OSID =
					    [OFString stringWithFormat: @"%c",
					    entry.operatingSystemIdentifier];

					[of_stdout writeString: @"\t"];
					[of_stdout writeLine: OF_LOCALIZED(
					    @"list_osid",
					    @"Operating system identifier: "
					    "%[osid]",
					    @"osid", OSID)];
				}

				if (entry.modificationDate != nil) {
					OFString *modificationDate =
					    entry.modificationDate.description;

					[of_stdout writeString: @"\t"];
					[of_stdout writeLine: OF_LOCALIZED(
					    @"list_modification_date",
					    @"Modification date: %[date]",
					    @"date", modificationDate)];
				}
			}

			if (app->_outputLevel >= 3) {
				OFString *extensions =
				    indent(entry.extensions.description);

				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_extensions",
				    @"Extensions: %[extensions]",
				    @"extensions", extensions)];
			}
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];
	bool all = (files.count == 0);
	OFMutableSet OF_GENERIC(OFString *) *missing =
	    [OFMutableSet setWithArray: files];
	OFLHAArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFString *outFileName, *directory;
		OFFile *output;
		OFStream *stream;
		uint64_t written = 0, size = entry.uncompressedSize;
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

		[missing removeObject: fileName];

		outFileName = [app safeLocalPathForPath: fileName];
		if (outFileName == nil) {
			[of_stderr writeLine: OF_LOCALIZED(
			    @"refusing_to_extract_file",
			    @"Refusing to extract %[file]!",
			    @"file", fileName)];

			app->_exitStatus = 1;
			goto outer_loop_end;
		}

		if (app->_outputLevel >= 0)
			[of_stdout writeString: OF_LOCALIZED(@"extracting_file",
			    @"Extracting %[file]...",
			    @"file", fileName)];

		if ([fileName hasSuffix: @"/"]) {
			[fileManager createDirectoryAtPath: outFileName
					     createParents: true];
			setPermissions(outFileName, entry);
			setModificationDate(outFileName, entry);

			if (app->_outputLevel >= 0) {
				[of_stdout writeString: @"\r"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"extracting_file_done",
				    @"Extracting %[file]... done",
				    @"file", fileName)];
			}

			goto outer_loop_end;
		}

		directory = outFileName.stringByDeletingLastPathComponent;
		if (![fileManager directoryExistsAtPath: directory])
			[fileManager createDirectoryAtPath: directory
					     createParents: true];

		if (![app shouldExtractFile: fileName
				outFileName: outFileName])
			goto outer_loop_end;

		stream = [_archive streamForReadingCurrentEntry];
		output = [OFFile fileWithPath: outFileName
					 mode: @"w"];
		setPermissions(outFileName, entry);

		while (!stream.atEndOfStream) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: output
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				goto outer_loop_end;
			}

			written += length;
			newPercent = (written == size
			    ? 100 : (int8_t)(written * 100 / size));

			if (app->_outputLevel >= 0 && percent != newPercent) {
				OFString *percentString;

				percent = newPercent;
				percentString = [OFString stringWithFormat:
				    @"%3u", percent];

				[of_stdout writeString: @"\r"];
				[of_stdout writeString: OF_LOCALIZED(
				    @"extracting_file_percent",
				    @"Extracting %[file]... %[percent]%",
				    @"file", fileName,
				    @"percent", percentString)];
			}
		}

		[output close];
		setModificationDate(outFileName, entry);

		if (app->_outputLevel >= 0) {
			[of_stdout writeString: @"\r"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"extracting_file_done",
			    @"Extracting %[file]... done",
			    @"file", fileName)];
		}

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	if (missing.count > 0) {
		for (OFString *file in missing)
			[of_stderr writeLine: OF_LOCALIZED(
			    @"file_not_in_archive",
			    @"File %[file] is not in the archive!",
			    @"file", file)];

		app->_exitStatus = 1;
	}
}

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files_
{
	OFMutableSet *files;
	OFLHAArchiveEntry *entry;

	if (files_.count < 1) {
		[of_stderr writeLine: OF_LOCALIZED(@"print_no_file_specified",
		    @"Need one or more files to print!")];
		app->_exitStatus = 1;
		return;
	}

	files = [OFMutableSet setWithArray: files_];

	while ((entry = [_archive nextEntry]) != nil) {
		OFString *fileName = entry.fileName;
		OFStream *stream;

		if (![files containsObject: fileName])
			continue;

		stream = [_archive streamForReadingCurrentEntry];

		while (!stream.atEndOfStream) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: of_stdout
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[files removeObject: fileName];
		[stream close];

		if (files.count == 0)
			break;
	}

	for (OFString *file in files) {
		[of_stderr writeLine: OF_LOCALIZED(@"file_not_in_archive",
		    @"File %[file] is not in the archive!",
		    @"file", file)];
		app->_exitStatus = 1;
	}
}

- (void)addFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];

	if (files.count < 1) {
		[of_stderr writeLine: OF_LOCALIZED(@"add_no_file_specified",
		    @"Need one or more files to add!")];
		app->_exitStatus = 1;
		return;
	}

	for (OFString *fileName in files) {
		void *pool = objc_autoreleasePoolPush();
		of_file_attributes_t attributes;
		of_file_type_t type;
		OFMutableLHAArchiveEntry *entry;
		OFStream *output;

		if (app->_outputLevel >= 0)
			[of_stdout writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		attributes = [fileManager attributesOfItemAtPath: fileName];
		type = attributes.fileType;
		entry = [OFMutableLHAArchiveEntry entryWithFileName: fileName];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
		entry.mode = [OFNumber numberWithUnsignedLong:
		    attributes.filePOSIXPermissions];
#endif
		entry.date = attributes.fileModificationDate;

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
		entry.UID =
		    [OFNumber numberWithUnsignedLong: attributes.filePOSIXUID];
		entry.GID =
		    [OFNumber numberWithUnsignedLong: attributes.filePOSIXGID];
		entry.owner = attributes.fileOwner;
		entry.group = attributes.fileGroup;
#endif

		if ([type isEqual: of_file_type_directory])
			entry.compressionMethod = @"-lhd-";

		output = [_archive streamForWritingEntry: entry];

		if ([type isEqual: of_file_type_regular]) {
			unsigned long long written = 0;
			unsigned long long size = attributes.fileSize;
			int8_t percent = -1, newPercent;

			OFFile *input = [OFFile fileWithPath: fileName
							mode: @"r"];

			while (!input.atEndOfStream) {
				ssize_t length = [app
				    copyBlockFromStream: input
					       toStream: output
					       fileName: fileName];

				if (length < 0) {
					app->_exitStatus = 1;
					goto outer_loop_end;
				}

				written += length;
				newPercent = (written == size
				    ? 100 : (int8_t)(written * 100 / size));

				if (app->_outputLevel >= 0 &&
				    percent != newPercent) {
					OFString *percentString;

					percent = newPercent;
					percentString = [OFString
					    stringWithFormat: @"%3u", percent];

					[of_stdout writeString: @"\r"];
					[of_stdout writeString: OF_LOCALIZED(
					    @"adding_file_percent",
					    @"Adding %[file]... %[percent]%",
					    @"file", fileName,
					    @"percent", percentString)];
				}
			}
		}

		if (app->_outputLevel >= 0) {
			[of_stdout writeString: @"\r"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"adding_file_done",
			    @"Adding %[file]... done",
			    @"file", fileName)];
		}

		[output close];

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	[_archive close];
}
@end
