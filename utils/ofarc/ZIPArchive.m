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

#include <errno.h>

#import "OFApplication.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "ZIPArchive.h"
#import "OFArc.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"

static OFArc *app;

static void
setPermissions(OFString *path, OFZIPArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	if ((entry.versionMadeBy >> 8) ==
	    OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX) {
		uint16_t mode = entry.versionSpecificAttributes >> 16;
		of_file_attribute_key_t key =
		    of_file_attribute_key_posix_permissions;
		of_file_attributes_t attributes = [OFDictionary
		    dictionaryWithObject: [OFNumber numberWithUInt16: mode]
				  forKey: key];

		[[OFFileManager defaultManager] setAttributes: attributes
						 ofItemAtPath: path];
	}
#endif
}

@implementation ZIPArchive
+ (void)initialize
{
	if (self == [ZIPArchive class])
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
		_archive = [[OFZIPArchive alloc] initWithStream: stream
							   mode: mode];
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
	for (OFZIPArchiveEntry *entry in _archive.entries) {
		void *pool = objc_autoreleasePoolPush();

		[of_stdout writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *compressedSize = [OFString
			    stringWithFormat: @"%" PRIu64,
					      entry.compressedSize];
			OFString *uncompressedSize = [OFString
			    stringWithFormat: @"%" PRIu64,
					      entry.uncompressedSize];
			OFString *compressionMethod =
			    of_zip_archive_entry_compression_method_to_string(
			    entry.compressionMethod);
			OFString *CRC32 = [OFString
			    stringWithFormat: @"%08" PRIX32, entry.CRC32];
			OFString *modificationDate = [entry.modificationDate
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];

			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_compressed_size",
			    @"Compressed: %[size] bytes",
			    @"size", compressedSize)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_uncompressed_size",
			    @"Uncompressed: %[size] bytes",
			    @"size", uncompressedSize)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_compression_method",
			    @"Compression method: %[method]",
			    @"method", compressionMethod)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(@"list_crc32",
			    @"CRC32: %[crc32]",
			    @"crc32", CRC32)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", modificationDate)];

			if (app->_outputLevel >= 2) {
				uint16_t versionMadeBy = entry.versionMadeBy;

				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_version_made_by",
				    @"Version made by: %[version]",
				    @"version",
				    of_zip_archive_entry_version_to_string(
				    versionMadeBy))];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_min_version_needed",
				    @"Minimum version needed: %[version]",
				    @"version",
				    of_zip_archive_entry_version_to_string(
				    entry.minVersionNeeded))];

				if ((versionMadeBy >> 8) ==
				    OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX) {
					uint32_t mode = entry
					    .versionSpecificAttributes >> 16;
					OFString *modeString = [OFString
					    stringWithFormat: @"%06o", mode];
					[of_stdout writeString: @"\t"];
					[of_stdout writeLine: OF_LOCALIZED(
					    @"list_mode",
					    @"Mode: %[mode]",
					    @"mode", modeString)];
				}
			}

			if (app->_outputLevel >= 3) {
				OFString *GPBF = [OFString stringWithFormat:
				    @"%04" PRIx16, entry.generalPurposeBitFlag];

				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_general_purpose_bit_flag",
				    @"General purpose bit flag: %[gpbf]",
				    @"gpbf", GPBF)];

				if (entry.extraField != nil) {
					[of_stdout writeString: @"\t"];
					[of_stdout writeLine: OF_LOCALIZED(
					    @"list_extra_field",
					    @"Extra field: %[extra]",
					    @"extra",
					    entry.extraField.description)];
				}
			}

			if (entry.fileComment.length > 0) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_comment",
				    @"Comment: %[comment]",
				    @"comment", entry.fileComment)];
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

	for (OFZIPArchiveEntry *entry in _archive.entries) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFString *outFileName, *directory;
		OFStream *stream;
		OFFile *output;
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

		stream = [_archive streamForReadingFile: fileName];
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

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFStream *stream;

	if (files.count < 1) {
		[of_stderr writeLine: OF_LOCALIZED(@"print_no_file_specified",
		    @"Need one or more files to print!")];
		app->_exitStatus = 1;
		return;
	}

	for (OFString *path in files) {
		@try {
			stream = [_archive streamForReadingFile: path];
		} @catch (OFOpenItemFailedException *e) {
			if (e.errNo == ENOENT) {
				[of_stderr writeLine: OF_LOCALIZED(
				    @"file_not_in_archive",
				    @"File %[file] is not in the archive!",
				    @"file", e.path)];
				app->_exitStatus = 1;
				continue;
			}

			@throw e;
		}

		while (!stream.atEndOfStream) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: of_stdout
							 fileName: path];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[stream close];
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

	for (OFString *localFileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFArray OF_GENERIC (OFString *) *components;
		OFString *fileName;
		of_file_attributes_t attributes;
		bool isDirectory = false;
		OFMutableZIPArchiveEntry *entry;
		uintmax_t size;
		OFStream *output;

		components = localFileName.pathComponents;
		fileName = [components componentsJoinedByString: @"/"];

		attributes = [fileManager
		    attributesOfItemAtPath: localFileName];

		if ([attributes.fileType isEqual: of_file_type_directory]) {
			isDirectory = true;
			fileName = [fileName stringByAppendingString: @"/"];
		}

		if (app->_outputLevel >= 0)
			[of_stdout writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		entry = [OFMutableZIPArchiveEntry entryWithFileName: fileName];

		size = (isDirectory ? 0 : attributes.fileSize);
		if (size > INT64_MAX)
			@throw [OFOutOfRangeException exception];

		entry.compressedSize = (int64_t)size;
		entry.uncompressedSize = (int64_t)size;

		entry.compressionMethod =
		    OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE;
		entry.modificationDate = attributes.fileModificationDate;

		[entry makeImmutable];

		output = [_archive streamForWritingEntry: entry];

		if (!isDirectory) {
			uintmax_t written = 0;
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
