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

#define _LARGEFILE64_SOURCE

#include <errno.h>
#include <math.h>

#ifdef HAVE_DIRENT_H
# include <dirent.h>
#endif
#include "unistd_wrapper.h"

#import "platform.h"
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#include <sys/time.h>
#ifdef OF_WINDOWS
# include <utime.h>
#endif

#ifdef HAVE_PWD_H
# include <pwd.h>
#endif
#ifdef HAVE_GRP_H
# include <grp.h>
#endif

#import "OFFileURLHandler.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSystemInfo.h"
#import "OFURL.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFRemoveItemFailedException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFSetItemAttributesFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
# include <wchar.h>
#endif

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
# include <proto/locale.h>
# ifdef OF_AMIGAOS4
#  define DeleteFile(path) Delete(path)
# endif
#endif

#if defined(OF_WINDOWS) || defined(OF_AMIGAOS)
typedef struct {
	OFFileOffset st_size;
	unsigned int st_mode;
	OFTimeInterval st_atime, st_mtime, st_ctime;
# ifdef OF_WINDOWS
#  define HAVE_STRUCT_STAT_ST_BIRTHTIME
	OFTimeInterval st_birthtime;
	DWORD fileAttributes;
# endif
} Stat;
#elif defined(HAVE_STAT64)
typedef struct stat64 Stat;
#else
typedef struct stat Stat;
#endif

#ifdef OF_WINDOWS
# define S_IFLNK 0x10000
# define S_ISLNK(mode) (mode & S_IFLNK)
#endif

#if defined(OF_FILE_MANAGER_SUPPORTS_OWNER) && defined(OF_HAVE_THREADS)
static OFMutex *passwdMutex;

static void
releasePasswdMutex(void)
{
	[passwdMutex release];
}
#endif
#if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS) && !defined(OF_WINDOWS)
static OFMutex *readdirMutex;

static void
releaseReaddirMutex(void)
{
	[readdirMutex release];
}
#endif

#ifdef OF_WINDOWS
static int (*_wutime64FuncPtr)(const wchar_t *, struct __utimbuf64 *);
static WINAPI BOOLEAN (*createSymbolicLinkWFuncPtr)(LPCWSTR, LPCWSTR, DWORD);
static WINAPI BOOLEAN (*createHardLinkWFuncPtr)(LPCWSTR, LPCWSTR,
    LPSECURITY_ATTRIBUTES);
#endif

#ifdef OF_WINDOWS
static OFTimeInterval
filetimeToTimeInterval(const FILETIME *filetime)
{
	return (double)((int64_t)filetime->dwHighDateTime << 32 |
	    filetime->dwLowDateTime) / 10000000.0 - 11644473600.0;
}

static int
retrieveError(void)
{
	switch (GetLastError()) {
	case ERROR_FILE_NOT_FOUND:
	case ERROR_PATH_NOT_FOUND:
	case ERROR_NO_MORE_FILES:
		return ENOENT;
	case ERROR_ACCESS_DENIED:
		return EACCES;
	case ERROR_DIRECTORY:
		return ENOTDIR;
	case ERROR_NOT_READY:
		return EBUSY;
	default:
		return EIO;
	}
}
#endif

#ifdef OF_AMIGAOS
static int
retrieveError(void)
{
	switch (IoErr()) {
	case ERROR_DELETE_PROTECTED:
	case ERROR_READ_PROTECTED:
	case ERROR_WRITE_PROTECTED:
		return EACCES;
	case ERROR_DISK_NOT_VALIDATED:
	case ERROR_OBJECT_IN_USE:
		return EBUSY;
	case ERROR_OBJECT_EXISTS:
		return EEXIST;
	case ERROR_DIR_NOT_FOUND:
	case ERROR_NO_MORE_ENTRIES:
	case ERROR_OBJECT_NOT_FOUND:
		return ENOENT;
	case ERROR_NO_FREE_STORE:
		return ENOMEM;
	case ERROR_DISK_FULL:
		return ENOSPC;
	case ERROR_DIRECTORY_NOT_EMPTY:
		return ENOTEMPTY;
	case ERROR_DISK_WRITE_PROTECTED:
		return EROFS;
	case ERROR_RENAME_ACROSS_DEVICES:
		return EXDEV;
	default:
		return EIO;
	}
}
#endif

static int
statWrapper(OFString *path, Stat *buffer)
{
#if defined(OF_WINDOWS)
	WIN32_FILE_ATTRIBUTE_DATA data;
	bool success;

	if ([OFSystemInfo isWindowsNT])
		success = GetFileAttributesExW(path.UTF16String,
		    GetFileExInfoStandard, &data);
	else
		success = GetFileAttributesExA(
		    [path cStringWithEncoding: [OFLocale encoding]],
		    GetFileExInfoStandard, &data);

	if (!success)
		return retrieveError();

	buffer->st_size = (uint64_t)data.nFileSizeHigh << 32 |
	    data.nFileSizeLow;

	if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		buffer->st_mode = S_IFDIR;
	else if (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
		/*
		 * No need to use A functions in this branch: This is only
		 * available on NTFS (and hence Windows NT) anyway.
		 */
		WIN32_FIND_DATAW findData;
		HANDLE findHandle;

		if ((findHandle = FindFirstFileW(path.UTF16String,
		    &findData)) == INVALID_HANDLE_VALUE)
			return retrieveError();

		@try {
			if (!(findData.dwFileAttributes &
			    FILE_ATTRIBUTE_REPARSE_POINT))
				/* Race? Indicate to try again. */
				return EAGAIN;

			buffer->st_mode =
			    (findData.dwReserved0 == IO_REPARSE_TAG_SYMLINK
			    ? S_IFLNK : S_IFREG);
		} @finally {
			FindClose(findHandle);
		}
	} else
		buffer->st_mode = S_IFREG;

	buffer->st_mode |= (data.dwFileAttributes & FILE_ATTRIBUTE_READONLY
	    ? (S_IRUSR | S_IXUSR) : (S_IRUSR | S_IWUSR | S_IXUSR));

	buffer->st_atime = filetimeToTimeInterval(&data.ftLastAccessTime);
	buffer->st_mtime = filetimeToTimeInterval(&data.ftLastWriteTime);
	buffer->st_ctime = buffer->st_birthtime =
	    filetimeToTimeInterval(&data.ftCreationTime);
	buffer->fileAttributes = data.dwFileAttributes;

	return 0;
#elif defined(OF_AMIGAOS)
	BPTR lock;
# ifdef OF_AMIGAOS4
	struct ExamineData *ed;
# else
	struct FileInfoBlock fib;
# endif
	OFTimeInterval timeInterval;
	struct Locale *locale;
	struct DateStamp *date;

	if ((lock = Lock([path cStringWithEncoding: [OFLocale encoding]],
	    SHARED_LOCK)) == 0)
		return retrieveError();

# if defined(OF_MORPHOS)
	if (!Examine64(lock, &fib, TAG_DONE)) {
# elif defined(OF_AMIGAOS4)
	if ((ed = ExamineObjectTags(EX_FileLockInput, lock, TAG_END)) == NULL) {
# else
	if (!Examine(lock, &fib)) {
# endif
		int error = retrieveError();
		UnLock(lock);
		return error;
	}

	UnLock(lock);

# if defined(OF_MORPHOS)
	buffer->st_size = fib.fib_Size64;
# elif defined(OF_AMIGAOS4)
	buffer->st_size = ed->FileSize;
# else
	buffer->st_size = fib.fib_Size;
# endif
# ifdef OF_AMIGAOS4
	buffer->st_mode = (EXD_IS_DIRECTORY(ed) ? S_IFDIR : S_IFREG);
# else
	buffer->st_mode = (fib.fib_DirEntryType > 0 ? S_IFDIR : S_IFREG);
# endif

	timeInterval = 252460800;	/* 1978-01-01 */

	locale = OpenLocale(NULL);
	/*
	 * FIXME: This does not take DST into account. But unfortunately, there
	 * is no way to figure out if DST was in effect when the file was
	 * modified.
	 */
	timeInterval += locale->loc_GMTOffset * 60.0;
	CloseLocale(locale);

# ifdef OF_AMIGAOS4
	date = &ed->Date;
# else
	date = &fib.fib_Date;
# endif
	timeInterval += date->ds_Days * 86400.0;
	timeInterval += date->ds_Minute * 60.0;
	timeInterval += date->ds_Tick / (OFTimeInterval)TICKS_PER_SECOND;

	buffer->st_atime = buffer->st_mtime = buffer->st_ctime = timeInterval;

# ifdef OF_AMIGAOS4
	FreeDosObject(DOS_EXAMINEDATA, ed);
# endif

	return 0;
#elif defined(HAVE_STAT64)
	if (stat64([path cStringWithEncoding: [OFLocale encoding]],
	    buffer) != 0)
		return errno;

	return 0;
#else
	if (stat([path cStringWithEncoding: [OFLocale encoding]], buffer) != 0)
		return errno;

	return 0;
#endif
}

static int
lstatWrapper(OFString *path, Stat *buffer)
{
#if defined(HAVE_LSTAT) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
# ifdef HAVE_LSTAT64
	if (lstat64([path cStringWithEncoding: [OFLocale encoding]],
	    buffer) != 0)
		return errno;
# else
	if (lstat([path cStringWithEncoding: [OFLocale encoding]], buffer) != 0)
		return errno;
# endif

	return 0;
#else
	return statWrapper(path, buffer);
#endif
}

static void
setTypeAttribute(OFMutableFileAttributes attributes, Stat *s)
{
	if (S_ISREG(s->st_mode))
		[attributes setObject: OFFileTypeRegular forKey: OFFileType];
	else if (S_ISDIR(s->st_mode))
		[attributes setObject: OFFileTypeDirectory forKey: OFFileType];
#ifdef S_ISLNK
	else if (S_ISLNK(s->st_mode))
		[attributes setObject: OFFileTypeSymbolicLink
			       forKey: OFFileType];
#endif
#ifdef S_ISFIFO
	else if (S_ISFIFO(s->st_mode))
		[attributes setObject: OFFileTypeFIFO forKey: OFFileType];
#endif
#ifdef S_ISCHR
	else if (S_ISCHR(s->st_mode))
		[attributes setObject: OFFileTypeCharacterSpecial
			       forKey: OFFileType];
#endif
#ifdef S_ISBLK
	else if (S_ISBLK(s->st_mode))
		[attributes setObject: OFFileTypeBlockSpecial
			       forKey: OFFileType];
#endif
#ifdef S_ISSOCK
	else if (S_ISSOCK(s->st_mode))
		[attributes setObject: OFFileTypeSocket forKey: OFFileType];
#endif
	else
		[attributes setObject: OFFileTypeUnknown forKey: OFFileType];
}

static void
setDateAttributes(OFMutableFileAttributes attributes, Stat *s)
{
	/* FIXME: We could be more precise on some OSes */
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_atime]
	       forKey: OFFileLastAccessDate];
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_mtime]
	       forKey: OFFileModificationDate];
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_ctime]
	       forKey: OFFileStatusChangeDate];
#ifdef HAVE_STRUCT_STAT_ST_BIRTHTIME
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_birthtime]
	       forKey: OFFileCreationDate];
#endif
}

static void
setOwnerAndGroupAttributes(OFMutableFileAttributes attributes, Stat *s)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
	[attributes setObject: [NSNumber numberWithUnsignedLong: s->st_uid]
		       forKey: OFFileOwnerAccountID];
	[attributes setObject: [NSNumber numberWithUnsignedLong: s->st_gid]
		       forKey: OFFileGroupOwnerAccountID];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		OFStringEncoding encoding = [OFLocale encoding];
		struct passwd *passwd = getpwuid(s->st_uid);
		struct group *group_ = getgrgid(s->st_gid);

		if (passwd != NULL) {
			OFString *owner = [OFString
			    stringWithCString: passwd->pw_name
				     encoding: encoding];

			[attributes setObject: owner
				       forKey: OFFileOwnerAccountName];
		}

		if (group_ != NULL) {
			OFString *group = [OFString
			    stringWithCString: group_->gr_name
				     encoding: encoding];

			[attributes setObject: group
				       forKey: OFFileGroupOwnerAccountName];
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
# endif
#endif
}

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
static void
setSymbolicLinkDestinationAttribute(OFMutableFileAttributes attributes,
    OFURL *URL)
{
	OFString *path = URL.fileSystemRepresentation;
# ifndef OF_WINDOWS
	OFStringEncoding encoding = [OFLocale encoding];
	char destinationC[PATH_MAX];
	ssize_t length;
	OFString *destination;

	length = readlink([path cStringWithEncoding: encoding], destinationC,
	    PATH_MAX);

	if (length < 0)
		@throw [OFRetrieveItemAttributesFailedException
		    exceptionWithURL: URL
			       errNo: errno];

	destination = [OFString stringWithCString: destinationC
					 encoding: encoding
					   length: length];

	[attributes setObject: destination
		       forKey: OFFileSymbolicLinkDestination];
# else
	HANDLE handle;
	OFString *destination;

	if (createSymbolicLinkWFuncPtr == NULL)
		return;

	if ((handle = CreateFileW(path.UTF16String, 0, (FILE_SHARE_READ |
	    FILE_SHARE_WRITE), NULL, OPEN_EXISTING,
	    FILE_FLAG_OPEN_REPARSE_POINT, NULL)) == INVALID_HANDLE_VALUE)
		@throw [OFRetrieveItemAttributesFailedException
		    exceptionWithURL: URL
			       errNo: retrieveError()];

	@try {
		union {
			char bytes[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
			REPARSE_DATA_BUFFER data;
		} buffer;
		DWORD size;
		wchar_t *tmp;

		if (!DeviceIoControl(handle, FSCTL_GET_REPARSE_POINT, NULL, 0,
		    buffer.bytes, MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &size,
		    NULL))
			@throw [OFRetrieveItemAttributesFailedException
			    exceptionWithURL: URL
				       errNo: retrieveError()];

		if (buffer.data.ReparseTag != IO_REPARSE_TAG_SYMLINK)
			@throw [OFRetrieveItemAttributesFailedException
			    exceptionWithURL: URL
				       errNo: retrieveError()];

#  define slrb buffer.data.SymbolicLinkReparseBuffer
		tmp = slrb.PathBuffer +
		    (slrb.SubstituteNameOffset / sizeof(wchar_t));

		destination = [OFString
		    stringWithUTF16String: tmp
				   length: slrb.SubstituteNameLength /
					   sizeof(wchar_t)];

		[attributes setObject: OFFileTypeSymbolicLink
			       forKey: OFFileType];
		[attributes setObject: destination
			       forKey: OFFileSymbolicLinkDestination];
#  undef slrb
	} @finally {
		CloseHandle(handle);
	}
# endif
}
#endif

@implementation OFFileURLHandler
+ (void)initialize
{
#ifdef OF_WINDOWS
	HMODULE module;
#endif

	if (self != [OFFileURLHandler class])
		return;

#if defined(OF_FILE_MANAGER_SUPPORTS_OWNER) && defined(OF_HAVE_THREADS)
	passwdMutex = [[OFMutex alloc] init];
	atexit(releasePasswdMutex);
#endif
#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
	readdirMutex = [[OFMutex alloc] init];
	atexit(releaseReaddirMutex);
#endif

#ifdef OF_WINDOWS
	if ((module = LoadLibrary("msvcrt.dll")) != NULL)
		_wutime64FuncPtr = (int (*)(const wchar_t *,
		    struct __utimbuf64 *))GetProcAddress(module, "_wutime64");

	if ((module = LoadLibrary("kernel32.dll")) != NULL) {
		createSymbolicLinkWFuncPtr =
		    (WINAPI BOOLEAN (*)(LPCWSTR, LPCWSTR, DWORD))
		    GetProcAddress(module, "CreateSymbolicLinkW");
		createHardLinkWFuncPtr =
		    (WINAPI BOOLEAN (*)(LPCWSTR, LPCWSTR,
		    LPSECURITY_ATTRIBUTES))
		    GetProcAddress(module, "CreateHardLinkW");
	}
#endif

	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];
}

+ (bool)of_directoryExistsAtPath: (OFString *)path
{
	Stat s;

	if (statWrapper(path, &s) != 0)
		return false;

	return S_ISDIR(s.st_mode);
}

- (OFStream *)openItemAtURL: (OFURL *)URL mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [[OFFile alloc]
	    initWithPath: URL.fileSystemRepresentation
		    mode: mode];

	objc_autoreleasePoolPop(pool);

	return [file autorelease];
}

- (OFFileAttributes)attributesOfItemAtURL: (OFURL *)URL
{
	OFMutableFileAttributes ret = [OFMutableDictionary dictionary];
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	int error;
	Stat s;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![[URL scheme] isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = URL.fileSystemRepresentation;

	if ((error = lstatWrapper(path, &s)) != 0)
		@throw [OFRetrieveItemAttributesFailedException
		    exceptionWithURL: URL
			       errNo: error];

	if (s.st_size < 0)
		@throw [OFOutOfRangeException exception];

	[ret setObject: [NSNumber numberWithUnsignedLongLong: s.st_size]
		forKey: OFFileSize];

	setTypeAttribute(ret, &s);

	[ret setObject: [NSNumber numberWithUnsignedLong: s.st_mode]
		forKey: OFFilePOSIXPermissions];

	setOwnerAndGroupAttributes(ret, &s);
	setDateAttributes(ret, &s);

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
	if (S_ISLNK(s.st_mode))
		setSymbolicLinkDestinationAttribute(ret, URL);
#endif

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)of_setLastAccessDate: (OFDate *)lastAccessDate
	 andModificationDate: (OFDate *)modificationDate
		 ofItemAtURL: (OFURL *)URL
		  attributes: (OFFileAttributes)attributes OF_DIRECT
{
	OFString *path = URL.fileSystemRepresentation;
	OFFileAttributeKey attributeKey = (modificationDate != nil
	    ? OFFileModificationDate : OFFileLastAccessDate);

	if (lastAccessDate == nil)
		lastAccessDate = modificationDate;
	if (modificationDate == nil)
		modificationDate = lastAccessDate;

#if defined(OF_WINDOWS)
	if (_wutime64FuncPtr != NULL) {
		struct __utimbuf64 times = {
			.actime =
			    (__time64_t)lastAccessDate.timeIntervalSince1970,
			.modtime =
			    (__time64_t)modificationDate.timeIntervalSince1970
		};

		if (_wutime64FuncPtr([path UTF16String], &times) != 0)
			@throw [OFSetItemAttributesFailedException
			    exceptionWithURL: URL
				  attributes: attributes
			     failedAttribute: attributeKey
				       errNo: errno];
	} else {
		struct _utimbuf times = {
			.actime = (time_t)lastAccessDate.timeIntervalSince1970,
			.modtime =
			    (time_t)modificationDate.timeIntervalSince1970
		};
		int status;

		if ([OFSystemInfo isWindowsNT])
			status = _wutime([path UTF16String], &times);
		else
			status = _utime(
			    [path cStringWithEncoding: [OFLocale encoding]],
			    &times);

		if (status != 0)
			@throw [OFSetItemAttributesFailedException
			    exceptionWithURL: URL
				  attributes: attributes
			     failedAttribute: attributeKey
				       errNo: errno];
	}
#elif defined(OF_AMIGAOS)
	/* AmigaOS does not support access time. */
	OFTimeInterval modificationTime =
	    modificationDate.timeIntervalSince1970;
	struct Locale *locale;
	struct DateStamp date;

	modificationTime -= 252460800;	/* 1978-01-01 */

	if (modificationTime < 0)
		@throw [OFOutOfRangeException exception];

	locale = OpenLocale(NULL);
	/*
	 * FIXME: This does not take DST into account. But unfortunately, there
	 *	  is no way to figure out if DST should be in effect for the
	 *	  timestamp.
	 */
	modificationTime -= locale->loc_GMTOffset * 60.0;
	CloseLocale(locale);

	date.ds_Days = modificationTime / 86400;
	date.ds_Minute = ((LONG)modificationTime % 86400) / 60;
	date.ds_Tick = fmod(modificationTime, 60) * TICKS_PER_SECOND;

# ifdef OF_AMIGAOS4
	if (!SetDate([path cStringWithEncoding: [OFLocale encoding]],
	    &date) != 0)
# else
	if (!SetFileDate([path cStringWithEncoding: [OFLocale encoding]],
	    &date) != 0)
# endif
		@throw [OFSetItemAttributesFailedException
		    exceptionWithURL: URL
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: retrieveError()];
#else
	OFTimeInterval lastAccessTime = lastAccessDate.timeIntervalSince1970;
	OFTimeInterval modificationTime =
	    modificationDate.timeIntervalSince1970;
	struct timeval times[2] = {
		{
			.tv_sec = (time_t)lastAccessTime,
			.tv_usec =
			    (int)((lastAccessTime - times[0].tv_sec) * 1000000)
		},
		{
			.tv_sec = (time_t)modificationTime,
			.tv_usec = (int)((modificationTime - times[1].tv_sec) *
			    1000000)
		},
	};

	if (utimes([path cStringWithEncoding: [OFLocale encoding]], times) != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithURL: URL
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: errno];
#endif
}

- (void)of_setPOSIXPermissions: (OFNumber *)permissions
		   ofItemAtURL: (OFURL *)URL
		    attributes: (OFFileAttributes)attributes OF_DIRECT
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	mode_t mode = (mode_t)permissions.unsignedLongValue;
	OFString *path = URL.fileSystemRepresentation;
	int status;

# ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wchmod(path.UTF16String, mode);
	else
# endif
		status = chmod(
		    [path cStringWithEncoding: [OFLocale encoding]], mode);

	if (status != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithURL: URL
			  attributes: attributes
		     failedAttribute: OFFilePOSIXPermissions
			       errNo: errno];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)of_setOwnerAccountName: (OFString *)owner
      andGroupOwnerAccountName: (OFString *)group
		   ofItemAtURL: (OFURL *)URL
		  attributeKey: (OFFileAttributeKey)attributeKey
		    attributes: (OFFileAttributes)attributes OF_DIRECT
{
#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
	OFString *path = URL.fileSystemRepresentation;
	uid_t uid = -1;
	gid_t gid = -1;
	OFStringEncoding encoding;

	if (owner == nil && group == nil)
		@throw [OFInvalidArgumentException exception];

	encoding = [OFLocale encoding];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFSetItemAttributesFailedException
				    exceptionWithURL: URL
					  attributes: attributes
				     failedAttribute: attributeKey
					       errNo: errno];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFSetItemAttributesFailedException
				    exceptionWithURL: URL
					  attributes: attributes
				     failedAttribute: attributeKey
					       errNo: errno];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
# endif

	if (chown([path cStringWithEncoding: encoding], uid, gid) != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithURL: URL
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: errno];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator OF_GENERIC(OFFileAttributeKey) *keyEnumerator;
	OFEnumerator *objectEnumerator;
	OFFileAttributeKey key;
	id object;
	OFDate *lastAccessDate, *modificationDate;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	keyEnumerator = [attributes keyEnumerator];
	objectEnumerator = [attributes objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		if ([key isEqual: OFFileModificationDate] ||
		    [key isEqual: OFFileLastAccessDate])
			continue;
		else if ([key isEqual: OFFilePOSIXPermissions])
			[self of_setPOSIXPermissions: object
					 ofItemAtURL: URL
					  attributes: attributes];
		else if ([key isEqual: OFFileOwnerAccountName])
			[self of_setOwnerAccountName: object
			    andGroupOwnerAccountName: nil
					 ofItemAtURL: URL
					attributeKey: key
					  attributes: attributes];
		else if ([key isEqual: OFFileGroupOwnerAccountName])
			[self of_setOwnerAccountName: nil
			    andGroupOwnerAccountName: object
					 ofItemAtURL: URL
					attributeKey: key
					  attributes: attributes];
		else
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
	}

	lastAccessDate = [attributes objectForKey: OFFileLastAccessDate];
	modificationDate = [attributes objectForKey: OFFileModificationDate];

	if (lastAccessDate != nil || modificationDate != nil)
		[self of_setLastAccessDate: lastAccessDate
		       andModificationDate: modificationDate
			       ofItemAtURL: URL
				attributes: attributes];

	objc_autoreleasePoolPop(pool);
}

- (bool)fileExistsAtURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();
	Stat s;
	bool ret;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	if (statWrapper(URL.fileSystemRepresentation, &s) != 0) {
		objc_autoreleasePoolPop(pool);
		return false;
	}

	ret = S_ISREG(s.st_mode);

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)directoryExistsAtURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();
	Stat s;
	bool ret;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	if (statWrapper(URL.fileSystemRepresentation, &s) != 0) {
		objc_autoreleasePoolPop(pool);
		return false;
	}

	ret = S_ISDIR(s.st_mode);

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)createDirectoryAtURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = URL.fileSystemRepresentation;

#if defined(OF_WINDOWS)
	int status;

	if ([OFSystemInfo isWindowsNT])
		status = _wmkdir(path.UTF16String);
	else
		status = _mkdir(
		    [path cStringWithEncoding: [OFLocale encoding]]);

	if (status != 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithURL: URL
			       errNo: errno];
#elif defined(OF_AMIGAOS)
	BPTR lock;

	if ((lock = CreateDir(
	    [path cStringWithEncoding: [OFLocale encoding]])) == 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithURL: URL
			       errNo: retrieveError()];

	UnLock(lock);
#else
	if (mkdir([path cStringWithEncoding: [OFLocale encoding]], 0777) != 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithURL: URL
			       errNo: errno];
#endif

	objc_autoreleasePoolPop(pool);
}

- (OFArray OF_GENERIC(OFURL *) *)contentsOfDirectoryAtURL: (OFURL *)URL
{
	OFMutableArray *URLs = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = URL.fileSystemRepresentation;

#if defined(OF_WINDOWS)
	HANDLE handle;

	path = [path stringByAppendingString: @"\\*"];

	if ([OFSystemInfo isWindowsNT]) {
		WIN32_FIND_DATAW fd;

		if ((handle = FindFirstFileW(path.UTF16String,
		    &fd)) == INVALID_HANDLE_VALUE)
			@throw [OFOpenItemFailedException
			    exceptionWithURL: URL
					mode: nil
				       errNo: retrieveError()];

		@try {
			do {
				OFString *file;

				if (wcscmp(fd.cFileName, L".") == 0 ||
				    wcscmp(fd.cFileName, L"..") == 0)
					continue;

				file = [[OFString alloc]
				    initWithUTF16String: fd.cFileName];
				@try {
					[URLs addObject: [URL
					    URLByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			} while (FindNextFileW(handle, &fd));

			if (GetLastError() != ERROR_NO_MORE_FILES)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: retrieveError()];
		} @finally {
			FindClose(handle);
		}
	} else {
		OFStringEncoding encoding = [OFLocale encoding];
		WIN32_FIND_DATA fd;

		if ((handle = FindFirstFileA(
		    [path cStringWithEncoding: encoding], &fd)) ==
		    INVALID_HANDLE_VALUE)
			@throw [OFOpenItemFailedException
			    exceptionWithURL: URL
					mode: nil
				       errNo: retrieveError()];

		@try {
			do {
				OFString *file;

				if (strcmp(fd.cFileName, ".") == 0 ||
				    strcmp(fd.cFileName, "..") == 0)
					continue;

				file = [[OFString alloc]
				    initWithCString: fd.cFileName
					   encoding: encoding];
				@try {
					[URLs addObject: [URL
					    URLByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			} while (FindNextFileA(handle, &fd));

			if (GetLastError() != ERROR_NO_MORE_FILES)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: retrieveError()];
		} @finally {
			FindClose(handle);
		}
	}
#elif defined(OF_AMIGAOS)
	OFStringEncoding encoding = [OFLocale encoding];
	BPTR lock;

	if ((lock = Lock([path cStringWithEncoding: encoding],
	    SHARED_LOCK)) == 0)
		@throw [OFOpenItemFailedException
		    exceptionWithURL: URL
				mode: nil
			       errNo: retrieveError()];

	@try {
# ifdef OF_AMIGAOS4
		struct ExamineData *ed;
		APTR context;

		if ((context = ObtainDirContextTags(EX_FileLockInput, lock,
		    EX_DoCurrentDir, TRUE, EX_DataFields, EXF_NAME,
		    TAG_END)) == NULL)
			@throw [OFOpenItemFailedException
			    exceptionWithURL: URL
					mode: nil
				       errNo: retrieveError()];

		@try {
			while ((ed = ExamineDir(context)) != NULL) {
				OFString *file = [[OFString alloc]
				    initWithCString: ed->Name
					   encoding: encoding];

				@try {
					[URLs addObject: [URL
					    URLByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			}
		} @finally {
			ReleaseDirContext(context);
		}
# else
		struct FileInfoBlock fib;

		if (!Examine(lock, &fib))
			@throw [OFOpenItemFailedException
			    exceptionWithURL: URL
					mode: nil
				       errNo: retrieveError()];

		while (ExNext(lock, &fib)) {
			OFString *file = [[OFString alloc]
			    initWithCString: fib.fib_FileName
				   encoding: encoding];
			@try {
				[URLs addObject:
				    [URL URLByAppendingPathComponent: file]];
			} @finally {
				[file release];
			}
		}
# endif

		if (IoErr() != ERROR_NO_MORE_ENTRIES)
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: 0
					  errNo: retrieveError()];
	} @finally {
		UnLock(lock);
	}
#else
	OFStringEncoding encoding = [OFLocale encoding];
	DIR *dir;
	if ((dir = opendir([path cStringWithEncoding: encoding])) == NULL)
		@throw [OFOpenItemFailedException exceptionWithURL: URL
							      mode: nil
							     errNo: errno];

# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
	@try {
		[readdirMutex lock];
	} @catch (id e) {
		closedir(dir);
		@throw e;
	}
# endif

	@try {
		for (;;) {
			struct dirent *dirent;
# ifdef HAVE_READDIR_R
			struct dirent buffer;
# endif
			OFString *file;

# ifdef HAVE_READDIR_R
			if (readdir_r(dir, &buffer, &dirent) != 0)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: errno];

			if (dirent == NULL)
				break;
# else
			errno = 0;
			if ((dirent = readdir(dir)) == NULL) {
				if (errno == 0)
					break;
				else
					@throw [OFReadFailedException
					    exceptionWithObject: self
						requestedLength: 0
							  errNo: errno];
			}
# endif

			if (strcmp(dirent->d_name, ".") == 0 ||
			    strcmp(dirent->d_name, "..") == 0)
				continue;

			file = [[OFString alloc] initWithCString: dirent->d_name
							encoding: encoding];
			@try {
				[URLs addObject:
				    [URL URLByAppendingPathComponent: file]];
			} @finally {
				[file release];
			}
		}
	} @finally {
		closedir(dir);
# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
		[readdirMutex unlock];
# endif
	}
#endif

	[URLs makeImmutable];

	objc_autoreleasePoolPop(pool);

	return URLs;
}

- (void)removeItemAtURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	int error;
	Stat s;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = URL.fileSystemRepresentation;

	if ((error = lstatWrapper(path, &s)) != 0)
		@throw [OFRemoveItemFailedException exceptionWithURL: URL
							       errNo: error];

	if (S_ISDIR(s.st_mode)) {
		OFArray OF_GENERIC(OFURL *) *contents;

		@try {
			contents = [self contentsOfDirectoryAtURL: URL];
		} @catch (id e) {
			/*
			 * Only convert exceptions to
			 * OFRemoveItemFailedException that have an errNo
			 * property. This covers all I/O related exceptions
			 * from the operations used to remove an item, all
			 * others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFRemoveItemFailedException
				    exceptionWithURL: URL
					       errNo: [e errNo]];

			@throw e;
		}

		for (OFURL *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();

			[self removeItemAtURL: item];

			objc_autoreleasePoolPop(pool2);
		}

#ifndef OF_AMIGAOS
		int status;

# ifdef OF_WINDOWS
		if ([OFSystemInfo isWindowsNT])
			status = _wrmdir(path.UTF16String);
		else
# endif
			status = rmdir(
			    [path cStringWithEncoding: [OFLocale encoding]]);

		if (status != 0)
			@throw [OFRemoveItemFailedException
				exceptionWithURL: URL
					   errNo: errno];
	} else {
		int status;

# ifdef OF_WINDOWS
		if ([OFSystemInfo isWindowsNT])
			status = _wunlink(path.UTF16String);
		else
# endif
			status = unlink(
			    [path cStringWithEncoding: [OFLocale encoding]]);

		if (status != 0)
			@throw [OFRemoveItemFailedException
			    exceptionWithURL: URL
				       errNo: errno];
#endif
	}

#ifdef OF_AMIGAOS
	if (!DeleteFile([path cStringWithEncoding: [OFLocale encoding]]))
		@throw [OFRemoveItemFailedException
		    exceptionWithURL: URL
			       errNo: retrieveError()];
#endif

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)linkItemAtURL: (OFURL *)source toURL: (OFURL *)destination
{
	void *pool = objc_autoreleasePoolPush();
	OFString *sourcePath, *destinationPath;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	if (![source.scheme isEqual: _scheme] ||
	    ![destination.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	sourcePath = source.fileSystemRepresentation;
	destinationPath = destination.fileSystemRepresentation;

# ifndef OF_WINDOWS
	OFStringEncoding encoding = [OFLocale encoding];

	if (link([sourcePath cStringWithEncoding: encoding],
	    [destinationPath cStringWithEncoding: encoding]) != 0)
		@throw [OFLinkFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: errno];
# else
	if (createHardLinkWFuncPtr == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (!createHardLinkWFuncPtr(destinationPath.UTF16String,
	    sourcePath.UTF16String, NULL))
		@throw [OFLinkFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: retrieveError()];
# endif

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)createSymbolicLinkAtURL: (OFURL *)URL
	    withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (URL == nil || target == nil)
		@throw [OFInvalidArgumentException exception];

	if (![URL.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = URL.fileSystemRepresentation;

# ifndef OF_WINDOWS
	OFStringEncoding encoding = [OFLocale encoding];

	if (symlink([target cStringWithEncoding: encoding],
	    [path cStringWithEncoding: encoding]) != 0)
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithURL: URL
			      target: target
			       errNo: errno];
# else
	if (createSymbolicLinkWFuncPtr == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (!createSymbolicLinkWFuncPtr(path.UTF16String, target.UTF16String,
	    0))
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithURL: URL
			      target: target
			       errNo: retrieveError()];
# endif

	objc_autoreleasePoolPop(pool);
}
#endif

- (bool)moveItemAtURL: (OFURL *)source toURL: (OFURL *)destination
{
	void *pool;

	if (![source.scheme isEqual: _scheme] ||
	    ![destination.scheme isEqual: _scheme])
		return false;

	if ([self fileExistsAtURL: destination])
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EEXIST];

	pool = objc_autoreleasePoolPush();

#ifdef OF_AMIGAOS
	OFStringEncoding encoding = [OFLocale encoding];

	if (!Rename([source.fileSystemRepresentation
	    cStringWithEncoding: encoding],
	    [destination.fileSystemRepresentation
	    cStringWithEncoding: encoding]))
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: retrieveError()];
#else
	int status;

# ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wrename(source.fileSystemRepresentation.UTF16String,
		    destination.fileSystemRepresentation.UTF16String);
	else {
# endif
		OFStringEncoding encoding = [OFLocale encoding];

		status = rename([source.fileSystemRepresentation
		    cStringWithEncoding: encoding],
		    [destination.fileSystemRepresentation
		    cStringWithEncoding: encoding]);
# ifdef OF_WINDOWS
	}
# endif

	if (status != 0)
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: errno];
#endif

	objc_autoreleasePoolPop(pool);

	return true;
}
@end
