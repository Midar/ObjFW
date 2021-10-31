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
#import "OFNotification.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
#ifdef OF_HAVE_THREADS
@class OFMutex;
#endif

/**
 * @class OFNotificationCenter OFNotificationCenter.h \
 *	  ObjFW/OFNotificationCenter.h
 *
 * @brief A class to send and register for notifications.
 */
@interface OFNotificationCenter: OFObject
{
#ifdef OF_HAVE_THREADS
	OFMutex *_mutex;
#endif
	OFMutableDictionary *_notifications;
	OF_RESERVE_IVARS(OFNotificationCenter, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFNotificationCenter *defaultCenter;
#endif

/**
 * @brief Returns the default notification center.
 */
+ (OFNotificationCenter *)defaultCenter;

/**
 * @brief Adds an observer for the specified notification and object.
 *
 * @param observer The object that should receive notifications
 * @param selector The selector to call on the observer on notifications. The
 *		   method must take exactly one object of type @ref
 *		   OFNotification.
 * @param name The name of the notification to observe
 * @param object The object that should be sending the notification, or `nil`
 *		 if the object should be ignored to determine what
 *		 notifications to deliver
 */
- (void)addObserver: (id)observer
	   selector: (SEL)selector
	       name: (OFNotificationName)name
	     object: (nullable id)object;

/**
 * @brief Removes an observer. All parameters must match those used with
 *	  @ref addObserver:selector:name:object:.
 *
 * @param observer The observer that was specified when adding the observer
 * @param selector The selector that was specified when adding the observer
 * @param name The name that was specified when adding the observer
 * @param object The object that was specified when adding the observer
 */
- (void)removeObserver: (id)observer
	      selector: (SEL)selector
		  name: (OFNotificationName)name
		object: (nullable id)object;

/**
 * @brief Posts the specified notification.
 *
 * @param notification The notification to post
 */
- (void)postNotification: (OFNotification *)notification;
@end

OF_ASSUME_NONNULL_END
