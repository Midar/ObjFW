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

#import "OFObject.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFTimer;
@class OFDate;
#ifdef OF_HAVE_THREADS
@class OFCondition;
#endif

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block to execute when a timer fires.
 *
 * @param timer The timer which fired
 */
typedef void (^of_timer_block_t)(OFTimer *timer);
#endif

/*!
 * @class OFTimer OFTimer.h ObjFW/OFTimer.h
 *
 * @brief A class for creating and firing timers.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFTimer: OFObject <OFComparing>
{
	OFDate *_fireDate;
	of_time_interval_t _interval;
	id _target;
	id _Nullable _object1, _object2, _object3, _object4;
	SEL _selector;
	uint8_t _arguments;
	bool _repeats;
#ifdef OF_HAVE_BLOCKS
	of_timer_block_t _block;
#endif
	bool _valid;
#ifdef OF_HAVE_THREADS
	OFCondition *_condition;
	bool _done;
#endif
	OFRunLoop *_Nullable _inRunLoop;
	of_run_loop_mode_t _Nullable _inRunLoopMode;
}

/*!
 * @brief The time interval in which the timer will repeat, if it is a
 *	  repeating timer.
 */
@property (readonly, nonatomic) of_time_interval_t timeInterval;

/*!
 * @brief Whether the timer is repeating.
 */
@property (readonly, nonatomic, getter=isRepeating) bool repeating;

/*!
 * @brief Whether the timer is valid.
 */
@property (readonly, nonatomic, getter=isValid) bool valid;

/*!
 * @brief The next date at which the timer will fire.
 *
 * If the timer is already scheduled in a run loop, it will be rescheduled.
 * Note that rescheduling is an expensive operation, though it still might be
 * preferable to reschedule instead of invalidating the timer and creating a
 * new one.
 */
@property (copy, nonatomic) OFDate *fireDate;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
					target: (id)target
				      selector: (SEL)selector
				       repeats: (bool)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object
				       repeats: (bool)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
				       repeats: (bool)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
					object: (nullable id)object3
				       repeats: (bool)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
					object: (nullable id)object3
					object: (nullable id)object4
				       repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (of_time_interval_t)timeInterval
				       repeats: (bool)repeats
					 block: (of_timer_block_t)block;
#endif

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			      repeats: (bool)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object
			      repeats: (bool)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			      repeats: (bool)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			       object: (nullable id)object3
			      repeats: (bool)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			       object: (nullable id)object3
			       object: (nullable id)object4
			      repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (of_time_interval_t)timeInterval
			      repeats: (bool)repeats
				block: (of_timer_block_t)block;
#endif

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			  target: (id)target
			selector: (SEL)selector
			 repeats: (bool)repeats;

/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object
			 repeats: (bool)repeats;

/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			 repeats: (bool)repeats;

/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			  object: (nullable id)object3
			 repeats: (bool)repeats;

/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			  object: (nullable id)object3
			  object: (nullable id)object4
			 repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (of_time_interval_t)interval
			 repeats: (bool)repeats
			   block: (of_timer_block_t)block;
#endif

/*!
 * @brief Fires the timer, meaning it will execute the specified selector on the
 *	  target.
 */
- (void)fire;

/*!
 * @brief Invalidates the timer, preventing it from firing.
 */
- (void)invalidate;

#ifdef OF_HAVE_THREADS
/*!
 * @brief Waits until the timer fired.
 */
- (void)waitUntilDone;
#endif
@end

OF_ASSUME_NONNULL_END
