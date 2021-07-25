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

#define OF_FILE_MANAGER_M

#include <errno.h>
#include <limits.h>
#include "unistd_wrapper.h"

#import "platform.h"

#ifdef OF_PSP
# include <sys/syslimits.h>
#endif

#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFURL.h"
#import "OFURLHandler.h"

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFCopyItemFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFGetCurrentDirectoryPathFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFRemoveItemFailedException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFUndefinedKeyException.h"
#import "OFUnsupportedProtocolException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
#endif

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
#endif

@interface OFDefaultFileManager: OFFileManager
@end

#ifdef OF_AMIGAOS4
# define CurrentDir(lock) SetCurrentDir(lock)
#endif

#include "OFFileManagerConstants.inc"

static OFFileManager *defaultManager;

#ifdef OF_AMIGAOS
static bool dirChanged = false;
static BPTR originalDirLock = 0;

OF_DESTRUCTOR()
{
	if (dirChanged)
		UnLock(CurrentDir(originalDirLock));
}
#endif

static id
attributeForKeyOrException(OFFileAttributes attributes, OFFileAttributeKey key)
{
	id object = [attributes objectForKey: key];

	if (object == nil)
		@throw [OFUndefinedKeyException exceptionWithObject: attributes
								key: key];

	return object;
}

@implementation OFFileManager
+ (void)initialize
{
	if (self != [OFFileManager class])
		return;

#ifdef OF_HAVE_FILES
	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];
#endif

	defaultManager = [[OFDefaultFileManager alloc] init];
}

+ (OFFileManager *)defaultManager
{
	return defaultManager;
}

#ifdef OF_HAVE_FILES
- (OFString *)currentDirectoryPath
{
# if defined(OF_WINDOWS)
	OFString *ret;

	if ([OFSystemInfo isWindowsNT]) {
		wchar_t *buffer = _wgetcwd(NULL, 0);

		@try {
			ret = [OFString stringWithUTF16String: buffer];
		} @finally {
			free(buffer);
		}
	} else {
		char *buffer = _getcwd(NULL, 0);

		@try {
			ret = [OFString stringWithCString: buffer
						 encoding: [OFLocale encoding]];
		} @finally {
			free(buffer);
		}
	}

	return ret;
# elif defined(OF_AMIGAOS)
	char buffer[512];

	if (!NameFromLock(((struct Process *)FindTask(NULL))->pr_CurrentDir,
	    buffer, 512)) {
		if (IoErr() == ERROR_LINE_TOO_LONG)
			@throw [OFOutOfRangeException exception];

		return nil;
	}

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
# else
	char buffer[PATH_MAX];

	if ((getcwd(buffer, PATH_MAX)) == NULL)
		@throw [OFGetCurrentDirectoryPathFailedException
		    exceptionWithErrNo: errno];

#  ifdef OF_DJGPP
	/*
	 * For some reason, getcwd() returns forward slashes on DJGPP, even
	 * though the native format is to use backwards slashes.
	 */
	for (char *tmp = buffer; *tmp != '\0'; tmp++)
		if (*tmp == '/')
			*tmp = '\\';
#  endif

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
# endif
}

- (OFURL *)currentDirectoryURL
{
	void *pool = objc_autoreleasePoolPush();
	OFURL *ret;

	ret = [OFURL fileURLWithPath: self.currentDirectoryPath];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}
#endif

- (OFFileAttributes)attributesOfItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler attributesOfItemAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (OFFileAttributes)attributesOfItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFileAttributes ret;

	ret = [self attributesOfItemAtURL: [OFURL fileURLWithPath: path]];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
#endif

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler setAttributes: attributes ofItemAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (void)setAttributes: (OFFileAttributes)attributes
	 ofItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	[self setAttributes: attributes
		ofItemAtURL: [OFURL fileURLWithPath: path]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (bool)fileExistsAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler fileExistsAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (bool)fileExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self fileExistsAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

- (bool)directoryExistsAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler directoryExistsAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (bool)directoryExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self directoryExistsAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

- (void)createDirectoryAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler createDirectoryAtURL: URL];
}

- (void)createDirectoryAtURL: (OFURL *)URL
	       createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableURL *mutableURL;
	OFArray OF_GENERIC(OFString *) *components;
	OFMutableArray OF_GENERIC(OFURL *) *componentURLs;
	size_t componentURLsCount;
	ssize_t i;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (!createParents) {
		[self createDirectoryAtURL: URL];
		return;
	}

	/*
	 * Try blindly creating the directory first.
	 *
	 * The reason for this is that we might be sandboxed, so attempting to
	 * create any of the parent directories will fail, while creating the
	 * directory itself will work.
	 */
	if ([self directoryExistsAtURL: URL])
		return;

	@try {
		[self createDirectoryAtURL: URL];
		return;
	} @catch (OFCreateDirectoryFailedException *e) {
		/*
		 * If we didn't fail because any of the parents is missing,
		 * there is no point in trying to create the parents.
		 */
		if (e.errNo != ENOENT)
			@throw e;
	}

	/*
	 * Because we might be sandboxed (and for remote URLs don't even know
	 * anything at all), we generate the URL for every component. We then
	 * iterate them in reverse order until we find the first existing
	 * directory, and then create subdirectories from there.
	 */
	mutableURL = [[URL mutableCopy] autorelease];
	mutableURL.URLEncodedPath = @"/";
	components = URL.pathComponents;
	componentURLs = [OFMutableArray arrayWithCapacity: components.count];

	for (OFString *component in components) {
		[mutableURL appendPathComponent: component];

		if (![mutableURL.URLEncodedPath isEqual: @"/"])
			[componentURLs addObject:
			    [[mutableURL copy] autorelease]];
	}

	componentURLsCount = componentURLs.count;
	for (i = componentURLsCount - 1; i > 0; i--) {
		if ([self directoryExistsAtURL:
		    [componentURLs objectAtIndex: i]])
			break;
	}

	if (++i == (ssize_t)componentURLsCount) {
		/*
		 * The URL exists, even though before we made sure it did not.
		 * That means it was created in the meantime by something else,
		 * so we're done here.
		 */
		objc_autoreleasePoolPop(pool);
		return;
	}

	for (; i < (ssize_t)componentURLsCount; i++)
		[self createDirectoryAtURL: [componentURLs objectAtIndex: i]];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_FILES
- (void)createDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);
}

- (void)createDirectoryAtPath: (OFString *)path
		createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURL: [OFURL fileURLWithPath: path]
		     createParents: createParents];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFArray OF_GENERIC(OFURL *) *)contentsOfDirectoryAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler contentsOfDirectoryAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFURL *) *URLs;
	OFMutableArray OF_GENERIC(OFString *) *ret;

	URLs = [self contentsOfDirectoryAtURL: [OFURL fileURLWithPath: path]];
	ret = [OFMutableArray arrayWithCapacity: URLs.count];

	for (OFURL *URL in URLs)
		[ret addObject: URL.lastPathComponent];

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFArray OF_GENERIC(OFString *) *)subpathsOfDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFString *) *ret =
	    [OFMutableArray arrayWithObject: path];

	for (OFString *subpath in [self contentsOfDirectoryAtPath: path]) {
		void *pool2 = objc_autoreleasePoolPush();
		OFString *fullSubpath =
		    [path stringByAppendingPathComponent: subpath];
		OFFileAttributes attributes =
		    [self attributesOfItemAtPath: fullSubpath];

		if ([attributes.fileType isEqual: OFFileTypeDirectory])
			[ret addObjectsFromArray:
			    [self subpathsOfDirectoryAtPath: fullSubpath]];
		else
			[ret addObject: fullSubpath];

		objc_autoreleasePoolPop(pool2);
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)changeCurrentDirectoryPath: (OFString *)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

# ifdef OF_AMIGAOS
	BPTR lock, oldLock;

	if ((lock = Lock([path cStringWithEncoding: [OFLocale encoding]],
	    SHARED_LOCK)) == 0) {
		int errNo;

		switch (IoErr()) {
		case ERROR_OBJECT_IN_USE:
		case ERROR_DISK_NOT_VALIDATED:
			errNo = EBUSY;
			break;
		case ERROR_OBJECT_NOT_FOUND:
			errNo = ENOENT;
			break;
		default:
			errNo = 0;
			break;
		}

		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errNo];
	}

	oldLock = CurrentDir(lock);

	if (!dirChanged)
		originalDirLock = oldLock;
	else
		UnLock(oldLock);

	dirChanged = true;
# else
	int status;

#  ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wchdir(path.UTF16String);
	else
#  endif
		status = chdir(
		    [path cStringWithEncoding: [OFLocale encoding]]);

	if (status != 0)
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errno];
# endif
}

- (void)changeCurrentDirectoryURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();

	[self changeCurrentDirectoryPath: URL.fileSystemRepresentation];

	objc_autoreleasePoolPop(pool);
}

- (void)copyItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();

	[self copyItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)copyItemAtURL: (OFURL *)source toURL: (OFURL *)destination
{
	void *pool;
	OFURLHandler *URLHandler;
	OFFileAttributes attributes;
	OFFileAttributeType type;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URLHandler = [OFURLHandler handlerForURL: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	if ([URLHandler copyItemAtURL: source toURL: destination])
		return;

	if ([self fileExistsAtURL: destination])
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EEXIST];

	@try {
		attributes = [self attributesOfItemAtURL: source];
	} @catch (OFRetrieveItemAttributesFailedException *e) {
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: e.errNo];
	}

	type = attributes.fileType;

	if ([type isEqual: OFFileTypeDirectory]) {
		OFArray OF_GENERIC(OFURL *) *contents;

		@try {
			[self createDirectoryAtURL: destination];

			@try {
				OFFileAttributeKey key = OFFilePOSIXPermissions;
				OFNumber *permissions =
				    [attributes objectForKey: key];
				OFFileAttributes destinationAttributes;

				if (permissions != nil) {
					destinationAttributes = [OFDictionary
					    dictionaryWithObject: permissions
							  forKey: key];
					[self
					    setAttributes: destinationAttributes
					      ofItemAtURL: destination];
				}
			} @catch (OFNotImplementedException *e) {
			}

			contents = [self contentsOfDirectoryAtURL: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		}

		for (OFURL *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();
			OFURL *destinationURL = [destination
			    URLByAppendingPathComponent:
			    item.lastPathComponent];

			[self copyItemAtURL: item toURL: destinationURL];

			objc_autoreleasePoolPop(pool2);
		}
	} else if ([type isEqual: OFFileTypeRegular]) {
		size_t pageSize = [OFSystemInfo pageSize];
		OFStream *sourceStream = nil;
		OFStream *destinationStream = nil;
		char *buffer;

		buffer = OFAllocMemory(1, pageSize);
		@try {
			sourceStream = [[OFURLHandler handlerForURL: source]
			    openItemAtURL: source
				     mode: @"r"];
			destinationStream = [[OFURLHandler handlerForURL:
			    destination] openItemAtURL: destination
						  mode: @"w"];

			while (!sourceStream.atEndOfStream) {
				size_t length;

				length = [sourceStream
				    readIntoBuffer: buffer
					    length: pageSize];
				[destinationStream writeBuffer: buffer
							length: length];
			}

			@try {
				OFFileAttributeKey key = OFFilePOSIXPermissions;
				OFNumber *permissions = [attributes
				    objectForKey: key];
				OFFileAttributes destinationAttributes;

				if (permissions != nil) {
					destinationAttributes = [OFDictionary
					    dictionaryWithObject: permissions
							  forKey: key];
					[self
					    setAttributes: destinationAttributes
					      ofItemAtURL: destination];
				}
			} @catch (OFNotImplementedException *e) {
			}
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		} @finally {
			[sourceStream close];
			[destinationStream close];
			OFFreeMemory(buffer);
		}
	} else if ([type isEqual: OFFileTypeSymbolicLink]) {
		@try {
			OFString *linkDestination =
			    attributes.fileSymbolicLinkDestination;

			[self createSymbolicLinkAtURL: destination
				  withDestinationPath: linkDestination];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		}
	} else
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EINVAL];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_FILES
- (void)moveItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();
	[self moveItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)moveItemAtURL: (OFURL *)source toURL: (OFURL *)destination
{
	void *pool;
	OFURLHandler *URLHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URLHandler = [OFURLHandler handlerForURL: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	@try {
		if ([URLHandler moveItemAtURL: source toURL: destination])
			return;
	} @catch (OFMoveItemFailedException *e) {
		if (e.errNo != EXDEV)
			@throw e;
	}

	if ([self fileExistsAtURL: destination])
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EEXIST];

	@try {
		[self copyItemAtURL: source toURL: destination];
	} @catch (OFCopyItemFailedException *e) {
		[self removeItemAtURL: destination];

		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: e.errNo];
	}

	@try {
		[self removeItemAtURL: source];
	} @catch (OFRemoveItemFailedException *e) {
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: e.errNo];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler removeItemAtURL: URL];
}

#ifdef OF_HAVE_FILES
- (void)removeItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	[self removeItemAtURL: [OFURL fileURLWithPath: path]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)linkItemAtURL: (OFURL *)source toURL: (OFURL *)destination
{
	void *pool = objc_autoreleasePoolPush();
	OFURLHandler *URLHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	if (![destination.scheme isEqual: source.scheme])
		@throw [OFInvalidArgumentException exception];

	URLHandler = [OFURLHandler handlerForURL: source];

	if (URLHandler == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	[URLHandler linkItemAtURL: source toURL: destination];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)linkItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();
	[self linkItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)createSymbolicLinkAtURL: (OFURL *)URL
	    withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	OFURLHandler *URLHandler;

	if (URL == nil || target == nil)
		@throw [OFInvalidArgumentException exception];

	URLHandler = [OFURLHandler handlerForURL: URL];

	if (URLHandler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler createSymbolicLinkAtURL: URL withDestinationPath: target];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)createSymbolicLinkAtPath: (OFString *)path
	     withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	[self createSymbolicLinkAtURL: [OFURL fileURLWithPath: path]
		  withDestinationPath: target];
	objc_autoreleasePoolPop(pool);
}
#endif
@end

@implementation OFDefaultFileManager
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
	return OFMaxRetainCount;
}
@end

@implementation OFDictionary (FileAttributes)
- (unsigned long long)fileSize
{
	return [attributeForKeyOrException(self, OFFileSize)
	    unsignedLongLongValue];
}

- (OFFileAttributeType)fileType
{
	return attributeForKeyOrException(self, OFFileType);
}

- (unsigned long)filePOSIXPermissions
{
	return [attributeForKeyOrException(self,
	    OFFilePOSIXPermissions) unsignedLongValue];
}

- (unsigned long)fileOwnerAccountID
{
	return [attributeForKeyOrException(self,
	    OFFileOwnerAccountID) unsignedLongValue];
}

- (unsigned long)fileGroupOwnerAccountID
{
	return [attributeForKeyOrException(self,
	    OFFileGroupOwnerAccountID) unsignedLongValue];
}

- (OFString *)fileOwnerAccountName
{
	return attributeForKeyOrException(self, OFFileOwnerAccountName);
}

- (OFString *)fileGroupOwnerAccountName
{
	return attributeForKeyOrException(self, OFFileGroupOwnerAccountName);
}

- (OFDate *)fileLastAccessDate
{
	return attributeForKeyOrException(self, OFFileLastAccessDate);
}

- (OFDate *)fileModificationDate
{
	return attributeForKeyOrException(self, OFFileModificationDate);
}

- (OFDate *)fileStatusChangeDate
{
	return attributeForKeyOrException(self, OFFileStatusChangeDate);
}

- (OFDate *)fileCreationDate
{
	return attributeForKeyOrException(self, OFFileCreationDate);
}

- (OFString *)fileSymbolicLinkDestination
{
	return attributeForKeyOrException(self, OFFileSymbolicLinkDestination);
}
@end
