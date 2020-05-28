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

#include <limits.h>
#include <time.h>
#include <math.h>

#include <sys/time.h>

#import "OFDate.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFMessagePackExtension.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFXMLElement.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "of_strptime.h"

#ifdef OF_AMIGAOS_M68K
/* amiga-gcc does not have trunc() */
# define trunc(x) ((int64_t)(x))
#endif

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_HAVE_THREADS)
static OFMutex *mutex;
#endif

#ifdef OF_WINDOWS
static __time64_t (*func__mktime64)(struct tm *);
#endif

#ifdef HAVE_GMTIME_R
# define GMTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	if (gmtime_r(&seconds, &tm) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm.field;
# define LOCALTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	if (localtime_r(&seconds, &tm) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm.field;
#else
# ifdef OF_HAVE_THREADS
#  define GMTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = gmtime(&seconds)) == NULL)			\
			@throw [OFOutOfRangeException exception];	\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
#  define LOCALTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	[mutex lock];							\
									\
	@try {								\
		if ((tm = localtime(&seconds)) == NULL)			\
			@throw [OFOutOfRangeException exception];	\
									\
		return tm->field;					\
	} @finally {							\
		[mutex unlock];						\
	}
# else
#  define GMTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	if ((tm = gmtime(&seconds)) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm->field;
#  define LOCALTIME_RET(field)						\
	time_t seconds = (time_t)_seconds;				\
	struct tm *tm;							\
									\
	if (seconds != trunc(_seconds))					\
		@throw [OFOutOfRangeException exception];		\
									\
	if ((tm = localtime(&seconds)) == NULL)				\
		@throw [OFOutOfRangeException exception];		\
									\
	return tm->field;
# endif
#endif

static int monthToDayOfYear[12] = {
	0,
	31,
	31 + 28,
	31 + 28 + 31,
	31 + 28 + 31 + 30,
	31 + 28 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
};

static double
tmAndTzToTime(struct tm *tm, int16_t *tz)
{
	double seconds;

	/* Years */
	seconds = (int64_t)(tm->tm_year - 70) * 31536000;
	/* Days of leap years, excluding the year to look at */
	seconds += (((tm->tm_year + 1899) / 4) - 492) * 86400;
	seconds -= (((tm->tm_year + 1899) / 100) - 19) * 86400;
	seconds += (((tm->tm_year + 1899) / 400) - 4) * 86400;
	/* Leap day */
	if (tm->tm_mon >= 2 && (((tm->tm_year + 1900) % 4 == 0 &&
	    (tm->tm_year + 1900) % 100 != 0) ||
	    (tm->tm_year + 1900) % 400 == 0))
		seconds += 86400;
	/* Months */
	if (tm->tm_mon < 0 || tm->tm_mon > 12)
		@throw [OFInvalidFormatException exception];
	seconds += monthToDayOfYear[tm->tm_mon] * 86400;
	/* Days */
	seconds += (tm->tm_mday - 1) * 86400;
	/* Hours */
	seconds += tm->tm_hour * 3600;
	/* Minutes */
	seconds += tm->tm_min * 60;
	/* Seconds */
	seconds += tm->tm_sec;
	/* Time zone */
	seconds += -(double)*tz * 60;

	return seconds;
}

@implementation OFDate
+ (void)initialize
{
#ifdef OF_WINDOWS
	HMODULE module;
#endif

	if (self != [OFDate class])
		return;

#if (!defined(HAVE_GMTIME_R) || !defined(HAVE_LOCALTIME_R)) && \
    defined(OF_HAVE_THREADS)
	mutex = [[OFMutex alloc] init];
#endif

#ifdef OF_WINDOWS
	if ((module = LoadLibrary("msvcrt.dll")) != NULL)
		func__mktime64 = (__time64_t (*)(struct tm *))
		    GetProcAddress(module, "_mktime64");
#endif
}

+ (instancetype)date
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dateWithTimeIntervalSince1970: (of_time_interval_t)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: seconds] autorelease];
}

+ (instancetype)dateWithTimeIntervalSinceNow: (of_time_interval_t)seconds
{
	return [[[self alloc]
	    initWithTimeIntervalSinceNow: seconds] autorelease];
}

+ (instancetype)dateWithDateString: (OFString *)string
			    format: (OFString *)format
{
	return [[[self alloc] initWithDateString: string
					  format: format] autorelease];
}

+ (instancetype)dateWithLocalDateString: (OFString *)string
				 format: (OFString *)format
{
	return [[[self alloc] initWithLocalDateString: string
					       format: format] autorelease];
}

+ (instancetype)distantFuture
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: 64060588800.0] autorelease];
}

+ (instancetype)distantPast
{
	return [[[self alloc]
	    initWithTimeIntervalSince1970: -62167219200.0] autorelease];
}

- (instancetype)init
{
	struct timeval t;

	self = [super init];

	OF_ENSURE(gettimeofday(&t, NULL) == 0);

	_seconds = t.tv_sec;
	_seconds += (of_time_interval_t)t.tv_usec / 1000000;

	return self;
}

- (instancetype)initWithTimeIntervalSince1970: (of_time_interval_t)seconds
{
	self = [super init];

	_seconds = seconds;

	return self;
}

- (instancetype)initWithTimeIntervalSinceNow: (of_time_interval_t)seconds
{
	self = [self init];

	_seconds += seconds;

	return self;
}

- (instancetype)initWithDateString: (OFString *)string
			    format: (OFString *)format
{
	self = [super init];

	@try {
		const char *UTF8String = string.UTF8String;
		struct tm tm = { 0 };
		int16_t tz = 0;

		tm.tm_isdst = -1;

		if (of_strptime(UTF8String, format.UTF8String,
		    &tm, &tz) != UTF8String + string.UTF8StringLength)
			@throw [OFInvalidFormatException exception];

		_seconds = tmAndTzToTime(&tm, &tz);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithLocalDateString: (OFString *)string
				 format: (OFString *)format
{
	self = [super init];

	@try {
		const char *UTF8String = string.UTF8String;
		struct tm tm = { 0 };
		/*
		 * of_strptime() can never set this to INT16_MAX, no matter
		 * what is passed to it, so this is a safe way to figure out if
		 * the date contains a time zone.
		 */
		int16_t tz = INT16_MAX;

		tm.tm_isdst = -1;

		if (of_strptime(UTF8String, format.UTF8String,
		    &tm, &tz) != UTF8String + string.UTF8StringLength)
			@throw [OFInvalidFormatException exception];

		if (tz == INT16_MAX) {
#ifdef OF_WINDOWS
			if (func__mktime64 != NULL) {
				if ((_seconds = func__mktime64(&tm)) == -1)
					@throw [OFInvalidFormatException
					    exception];
			} else {
#endif
				if ((_seconds = mktime(&tm)) == -1)
					@throw [OFInvalidFormatException
					    exception];
#ifdef OF_WINDOWS
			}
#endif
		} else
			_seconds = tmAndTzToTime(&tm, &tz);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		_seconds = OF_BSWAP_DOUBLE_IF_LE(OF_INT_TO_DOUBLE_RAW(
		    OF_BSWAP64_IF_LE(element.hexadecimalValue)));

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)isEqual: (id)object
{
	OFDate *otherDate;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFDate class]])
		return false;

	otherDate = object;

	if (otherDate->_seconds != _seconds)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;
	double tmp;

	OF_HASH_INIT(hash);

	tmp = OF_BSWAP_DOUBLE_IF_BE(_seconds);

	for (size_t i = 0; i < sizeof(double); i++)
		OF_HASH_ADD(hash, ((char *)&tmp)[i]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFDate *otherDate;

	if (![(id)object isKindOfClass: [OFDate class]])
		@throw [OFInvalidArgumentException exception];

	otherDate = (OFDate *)object;

	if (_seconds < otherDate->_seconds)
		return OF_ORDERED_ASCENDING;
	if (_seconds > otherDate->_seconds)
		return OF_ORDERED_DESCENDING;

	return OF_ORDERED_SAME;
}

- (OFString *)description
{
	return [self dateStringWithFormat: @"%Y-%m-%dT%H:%M:%SZ"];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OF_SERIALIZATION_NS];

	element.stringValue = [OFString stringWithFormat: @"%016" PRIx64,
	    OF_BSWAP64_IF_LE(OF_DOUBLE_TO_INT_RAW(OF_BSWAP_DOUBLE_IF_LE(
	    _seconds)))];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFData *)messagePackRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	int64_t seconds = (int64_t)_seconds;
	uint32_t nanoseconds = (_seconds - trunc(_seconds)) * 1000000000;
	OFData *ret;

	if (seconds >= 0 && seconds < 0x400000000) {
		if (seconds <= UINT32_MAX && nanoseconds == 0) {
			uint32_t seconds32 = (uint32_t)seconds;
			OFData *data;

			seconds32 = OF_BSWAP32_IF_LE(seconds32);
			data = [OFData dataWithItems: &seconds32
					       count: sizeof(seconds32)];

			ret = [[OFMessagePackExtension
			    extensionWithType: -1
					 data: data] messagePackRepresentation];
		} else {
			uint64_t combined = ((uint64_t)nanoseconds << 34) |
			    (uint64_t)seconds;
			OFData *data;

			combined = OF_BSWAP64_IF_LE(combined);
			data = [OFData dataWithItems: &combined
					       count: sizeof(combined)];

			ret = [[OFMessagePackExtension
			    extensionWithType: -1
					 data: data] messagePackRepresentation];
		}
	} else {
		OFMutableData *data = [OFMutableData dataWithCapacity: 12];

		seconds = OF_BSWAP64_IF_LE(seconds);
		nanoseconds = OF_BSWAP32_IF_LE(nanoseconds);

		[data addItems: &nanoseconds
			 count: sizeof(nanoseconds)];
		[data addItems: &seconds
			 count: sizeof(seconds)];

		ret = [[OFMessagePackExtension
		    extensionWithType: -1
				 data: data] messagePackRepresentation];
	}

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (uint32_t)microsecond
{
	return (uint32_t)((_seconds - trunc(_seconds)) * 1000000);
}

- (uint8_t)second
{
	GMTIME_RET(tm_sec)
}

- (uint8_t)minute
{
	GMTIME_RET(tm_min)
}

- (uint8_t)localMinute
{
	LOCALTIME_RET(tm_min)
}

- (uint8_t)hour
{
	GMTIME_RET(tm_hour)
}

- (uint8_t)localHour
{
	LOCALTIME_RET(tm_hour)
}

- (uint8_t)dayOfMonth
{
	GMTIME_RET(tm_mday)
}

- (uint8_t)localDayOfMonth
{
	LOCALTIME_RET(tm_mday)
}

- (uint8_t)monthOfYear
{
	GMTIME_RET(tm_mon + 1)
}

- (uint8_t)localMonthOfYear
{
	LOCALTIME_RET(tm_mon + 1)
}

- (uint16_t)year
{
	GMTIME_RET(tm_year + 1900)
}

- (uint16_t)localYear
{
	LOCALTIME_RET(tm_year + 1900)
}

- (uint8_t)dayOfWeek
{
	GMTIME_RET(tm_wday)
}

- (uint8_t)localDayOfWeek
{
	LOCALTIME_RET(tm_wday)
}

- (uint16_t)dayOfYear
{
	GMTIME_RET(tm_yday + 1)
}

- (uint16_t)localDayOfYear
{
	LOCALTIME_RET(tm_yday + 1)
}

- (OFString *)dateStringWithFormat: (OFConstantString *)format
{
	OFString *ret;
	time_t seconds = (time_t)_seconds;
	struct tm tm;
	size_t pageSize;
#ifndef OF_WINDOWS
	char *buffer;
#else
	wchar_t *buffer;
#endif

	if (seconds != trunc(_seconds))
		@throw [OFOutOfRangeException exception];

#ifdef HAVE_GMTIME_R
	if (gmtime_r(&seconds, &tm) == NULL)
		@throw [OFOutOfRangeException exception];
#else
# ifdef OF_HAVE_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = gmtime(&seconds)) == NULL)
			@throw [OFOutOfRangeException exception];

		tm = *tmp;
# ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];

	@try {
#ifndef OF_WINDOWS
		if (strftime(buffer, pageSize, format.UTF8String, &tm) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF8String: buffer];
#else
		if (wcsftime(buffer, pageSize / sizeof(wchar_t),
		    format.UTF16String, &tm) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF16String: buffer];
#endif
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString *)localDateStringWithFormat: (OFConstantString *)format
{
	OFString *ret;
	time_t seconds = (time_t)_seconds;
	struct tm tm;
	size_t pageSize;
#ifndef OF_WINDOWS
	char *buffer;
#else
	wchar_t *buffer;
#endif

	if (seconds != trunc(_seconds))
		@throw [OFOutOfRangeException exception];

#ifdef HAVE_LOCALTIME_R
	if (localtime_r(&seconds, &tm) == NULL)
		@throw [OFOutOfRangeException exception];
#else
# ifdef OF_HAVE_THREADS
	[mutex lock];

	@try {
# endif
		struct tm *tmp;

		if ((tmp = localtime(&seconds)) == NULL)
			@throw [OFOutOfRangeException exception];

		tm = *tmp;
# ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];

	@try {
#ifndef OF_WINDOWS
		if (strftime(buffer, pageSize, format.UTF8String, &tm) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF8String: buffer];
#else
		if (wcsftime(buffer, pageSize / sizeof(wchar_t),
		    format.UTF16String, &tm) == 0)
			@throw [OFOutOfRangeException exception];

		ret = [OFString stringWithUTF16String: buffer];
#endif
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFDate *)earlierDate: (OFDate *)otherDate
{
	if (otherDate == nil)
		return self;

	if ([self compare: otherDate] == OF_ORDERED_DESCENDING)
		return otherDate;

	return self;
}

- (OFDate *)laterDate: (OFDate *)otherDate
{
	if (otherDate == nil)
		return self;

	if ([self compare: otherDate] == OF_ORDERED_ASCENDING)
		return otherDate;

	return self;
}

- (of_time_interval_t)timeIntervalSince1970
{
	return _seconds;
}

- (of_time_interval_t)timeIntervalSinceDate: (OFDate *)otherDate
{
	return _seconds - otherDate->_seconds;
}

- (of_time_interval_t)timeIntervalSinceNow
{
	struct timeval t;
	of_time_interval_t seconds;

	OF_ENSURE(gettimeofday(&t, NULL) == 0);

	seconds = t.tv_sec;
	seconds += (of_time_interval_t)t.tv_usec / 1000000;

	return _seconds - seconds;
}

- (OFDate *)dateByAddingTimeInterval: (of_time_interval_t)seconds
{
	return [OFDate dateWithTimeIntervalSince1970: _seconds + seconds];
}
@end
