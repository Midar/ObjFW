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

#import "OFObject.h"
#import "OFMessagePackRepresentation.h"
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFConstantString;

/**
 * @class OFDate OFDate.h ObjFW/OFDate.h
 *
 * @brief A class for storing, accessing and comparing dates.
 */
#ifndef OF_DATE_M
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFDate: OFObject <OFCopying, OFComparing, OFSerialization,
    OFMessagePackRepresentation>
{
	of_time_interval_t _seconds;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFDate *distantFuture;
@property (class, readonly, nonatomic) OFDate *distantPast;
#endif

/**
 * @brief The microsecond of the date.
 */
@property (readonly, nonatomic) unsigned long microsecond;

/**
 * @brief The second of the date.
 */
@property (readonly, nonatomic) unsigned char second;

/**
 * @brief The minute of the date.
 */
@property (readonly, nonatomic) unsigned char minute;

/**
 * @brief The minute of the date in local time.
 */
@property (readonly, nonatomic) unsigned char localMinute;

/**
 * @brief The hour of the date.
 */
@property (readonly, nonatomic) unsigned char hour;

/**
 * @brief The hour of the date in local time.
 */
@property (readonly, nonatomic) unsigned char localHour;

/**
 * @brief The day of the month of the date.
 */
@property (readonly, nonatomic) unsigned char dayOfMonth;

/**
 * @brief The day of the month of the date in local time.
 */
@property (readonly, nonatomic) unsigned char localDayOfMonth;

/**
 * @brief The month of the year of the date.
 */
@property (readonly, nonatomic) unsigned char monthOfYear;

/**
 * @brief The month of the year of the date in local time.
 */
@property (readonly, nonatomic) unsigned char localMonthOfYear;

/**
 * @brief The year of the date.
 */
@property (readonly, nonatomic) unsigned short year;

/**
 * @brief The year of the date in local time.
 */
@property (readonly, nonatomic) unsigned short localYear;

/**
 * @brief The day of the week of the date.
 */
@property (readonly, nonatomic) unsigned char dayOfWeek;

/**
 * @brief The day of the week of the date in local time.
 */
@property (readonly, nonatomic) unsigned char localDayOfWeek;

/**
 * @brief The day of the year of the date.
 */
@property (readonly, nonatomic) unsigned short dayOfYear;

/**
 * @brief The day of the year of the date in local time.
 */
@property (readonly, nonatomic) unsigned short localDayOfYear;

/**
 * @brief The seconds since 1970-01-01T00:00:00Z.
 */
@property (readonly, nonatomic) of_time_interval_t timeIntervalSince1970;

/**
 * @brief The seconds the date is in the future.
 */
@property (readonly, nonatomic) of_time_interval_t timeIntervalSinceNow;

/**
 * @brief Creates a new OFDate with the current date and time.
 *
 * @return A new, autoreleased OFDate with the current date and time
 */
+ (instancetype)date;

/**
 * @brief Creates a new OFDate with the specified date and time since
 *	  1970-01-01T00:00:00Z.
 *
 * @param seconds The seconds since 1970-01-01T00:00:00Z
 * @return A new, autoreleased OFDate with the specified date and time
 */
+ (instancetype)dateWithTimeIntervalSince1970: (of_time_interval_t)seconds;

/**
 * @brief Creates a new OFDate with the specified date and time since now.
 *
 * @param seconds The seconds since now
 * @return A new, autoreleased OFDate with the specified date and time
 */
+ (instancetype)dateWithTimeIntervalSinceNow: (of_time_interval_t)seconds;

/**
 * @brief Creates a new OFDate with the specified string in the specified
 *	  format.
 *
 * The time zone used is UTC. See @ref dateWithLocalDateString:format: if you
 * want local time.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @warning The format is currently limited to the following format specifiers:
 *	    %%a, %%b, %%d, %%e, %%H, %%m, %%M, %%S, %%y, %%Y, %%z, %%, %%n and
 *	    %%t.
 *
 * @param string The string describing the date
 * @param format The format of the string describing the date
 * @return A new, autoreleased OFDate with the specified date and time
 */
+ (instancetype)dateWithDateString: (OFString *)string
			    format: (OFString *)format;

/**
 * @brief Creates a new OFDate with the specified string in the specified
 *	  format.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @warning The format is currently limited to the following format specifiers:
 *	    %%a, %%b, %%d, %%e, %%H, %%m, %%M, %%S, %%y, %%Y, %%z, %%, %%n and
 *	    %%t.
 *
 * @param string The string describing the date
 * @param format The format of the string describing the date
 * @return A new, autoreleased OFDate with the specified date and time
 */
+ (instancetype)dateWithLocalDateString: (OFString *)string
				 format: (OFString *)format;

/**
 * @brief Returns a date in the distant future.
 *
 * The date is system-dependant.
 *
 * @return A date in the distant future
 */
+ (instancetype)distantFuture;

/**
 * @brief Returns a date in the distant past.
 *
 * The date is system-dependant.
 *
 * @return A date in the distant past
 */
+ (instancetype)distantPast;

/**
 * @brief Initializes an already allocated OFDate with the specified date and
 *	  time since 1970-01-01T00:00:00Z.
 *
 * @param seconds The seconds since 1970-01-01T00:00:00Z
 * @return An initialized OFDate with the specified date and time
 */
- (instancetype)initWithTimeIntervalSince1970: (of_time_interval_t)seconds
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFDate with the specified date and
 *	  time since now.
 *
 * @param seconds The seconds since now
 * @return An initialized OFDate with the specified date and time
 */
- (instancetype)initWithTimeIntervalSinceNow: (of_time_interval_t)seconds;

/**
 * @brief Initializes an already allocated OFDate with the specified string in
 *	  the specified format.
 *
 * The time zone used is UTC. If a time zone is specified anyway, an
 * OFInvalidFormatException is thrown. See @ref initWithLocalDateString:format:
 * if you want to specify a time zone.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @warning The format is currently limited to the following format specifiers:
 *	    %%d, %%e, %%H, %%m, %%M, %%S, %%y, %%Y, %%, %%n and %%t.
 *
 * @param string The string describing the date
 * @param format The format of the string describing the date
 * @return An initialized OFDate with the specified date and time
 */
- (instancetype)initWithDateString: (OFString *)string
			    format: (OFString *)format;

/**
 * @brief Initializes an already allocated OFDate with the specified string in
 *	  the specified format.
 *
 * If no time zone is specified, local time is assumed.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @warning The format is currently limited to the following format specifiers:
 *	    %%d, %%e, %%H, %%m, %%M, %%S, %%y, %%Y, %%, %%n and %%t.
 *
 * @param string The string describing the date
 * @param format The format of the string describing the date
 * @return An initialized OFDate with the specified date and time
 */
- (instancetype)initWithLocalDateString: (OFString *)string
				 format: (OFString *)format;

/**
 * @brief Creates a string of the date with the specified format.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @param format The format for the date string
 * @return A new, autoreleased OFString
 */
- (OFString *)dateStringWithFormat: (OFConstantString *)format;

/**
 * @brief Creates a string of the local date with the specified format.
 *
 * See the man page for `strftime` for information on the format.
 *
 * @param format The format for the date string
 * @return A new, autoreleased OFString
 */
- (OFString *)localDateStringWithFormat: (OFConstantString *)format;

/**
 * @brief Returns the earlier of the two dates.
 *
 * If the argument is `nil`, it returns the receiver.
 *
 * @param otherDate Another date
 * @return The earlier date of the two dates
 */
- (OFDate *)earlierDate: (nullable OFDate *)otherDate;

/**
 * @brief Returns the later of the two dates.
 *
 * If the argument is `nil`, it returns the receiver.
 *
 * @param otherDate Another date
 * @return The later date of the two dates
 */
- (OFDate *)laterDate: (nullable OFDate *)otherDate;

/**
 * @brief Returns the seconds the receiver is after the date.
 *
 * @param otherDate Date date to generate the difference with receiver
 * @return The seconds the receiver is after the date.
 */
- (of_time_interval_t)timeIntervalSinceDate: (OFDate *)otherDate;

/**
 * @brief Creates a new date with the specified time interval added.
 *
 * @param seconds The seconds after the date
 * @return A new, autoreleased OFDate
 */
- (OFDate *)dateByAddingTimeInterval: (of_time_interval_t)seconds;
@end

OF_ASSUME_NONNULL_END
