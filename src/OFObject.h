/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
#endif

#define OF_RETAIN_COUNT_MAX UINT_MAX
#define OF_INVALID_INDEX SIZE_MAX

/**
 * \brief A result of a comparison.
 */
typedef enum of_comparison_result_t {
	/// The left object is smaller than the right
	OF_ORDERED_ASCENDING = -1,
	/// Both objects are equal
	OF_ORDERED_SAME = 0,
	/// The left object is bigger than the right
	OF_ORDERED_DESCENDING = 1
} of_comparison_result_t;

/**
 * \brief A range.
 */
typedef struct of_range_t {
	/// The start of the range
	size_t start;
	/// The length of the range
	size_t length;
} of_range_t;

@class OFString;

/**
 * \brief The protocol which all root classes implement.
 */
@protocol OFObject
/**
 * \return The class of the object
 */
- (Class)class;

/**
 * \param class_ The class whose kind is checked
 * \return A boolean whether the object is of the specified kind
 */
- (BOOL)isKindOfClass: (Class)class_;

/**
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether the objects responds to the specified selector
 */
- (BOOL)respondsToSelector: (SEL)selector;

/**
 * Performs the specified selector.
 *
 * \param selector The selector to perform
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector;

/**
 * Performs the specified selector with the specified object.
 *
 * \param selector The selector to perform
 * \param object The object that is passed to the method specified by the
 *		 selector
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector
	   withObject: (id)object;

/**
 * Performs the specified selector with the specified objects.
 *
 * \param selector The selector to perform
 * \param object The first object that is passed to the method specified by the
 *		 selector
 * \param otherObject The second object that is passed to the method specified
 *		      by the selector
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector
	   withObject: (id)object
	   withObject: (id)otherObject;

/**
 * Checks two objects for equality.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \param object The object which should be tested for equality
 * \return A boolean whether the object is equal to the specified object
 */
- (BOOL)isEqual: (id)object;

/**
 * Calculates a hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \return A 32 bit hash for the object
 */
- (uint32_t)hash;

/**
 * Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- retain;

/**
 * \return The retain count
 */
- (unsigned int)retainCount;

/**
 * Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/**
 * Adds the object to the topmost OFAutoreleasePool of the thread's release pool
 * stack.
 */
- autorelease;
@end

/**
 * \brief The root class for all other classes inside ObjFW.
 */
@interface OFObject <OFObject>
{
@public
	/// The class of the object
	Class isa;
}

/**
 * This code is executed once when the class is loaded into the runtime.
 *
 * Derived classes can overide this to execute their own code when the class is
 * loaded.
 */
+ (void)load;

/**
 * This code is executed once when a method of the class is called for the first
 * time.
 *
 * Derived classes can override this to execute their own code on
 * initialization.
 */
+ (void)initialize;

/**
 * Allocates memory for an instance of the class and sets up the memory pool for
 * the object.
 *
 * alloc will never return nil, instead, it will throw an
 * OFAllocFailedException.
 *
 * \return The allocated object.
 */
+ alloc;

/**
 * \return The class
 */
+ (Class)class;

/**
 * \return The name of the class as a C string
 */
+ (OFString*)className;

/**
 * \param class_ The class which is checked for being a superclass
 * \return A boolean whether the class class is a subclass of the specified
 *	   class
 */
+ (BOOL)isSubclassOfClass: (Class)class_;

/**
 * \return The superclass of the class
 */
+ (Class)superclass;

/**
 * Checks whether instances of the class respond to a given selector.
 *
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (BOOL)instancesRespondToSelector: (SEL)selector;

/**
 * Checks whether the class conforms to a given protocol.
 *
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the class conforms to the specified protocol
 */
+ (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \param selector The selector for which the method should be returned
 * \return The implementation of the instance method for the specified selector
 *	   or nil if it isn't implemented
 */
+ (IMP)instanceMethodForSelector: (SEL)selector;

/**
 * \param selector The selector for which the type encoding should be returned
 * \return The type encoding of the instance method for the specified selector
 */
+ (const char*)typeEncodingForInstanceSelector: (SEL)selector;

/**
 * Returns a description for the class, which is usually the class name.
 *
 * This is mostly for debugging purposes.
 */
+ (OFString*)description;

/**
 * Replaces a class method implementation with another implementation.
 *
 * \param newImp The new implementation for the class method
 * \param selector The selector of the class method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newImp
	  forClassMethod: (SEL)selector;

/**
 * Replaces a class method with a class method from another class.
 *
 * \param selector The selector of the class method to replace
 * \param class_ The class from which the new class method should be taken
 * \return The old implementation
 */
+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class_;

/**
 * Replaces an instance method implementation with another implementation.
 *
 * \param newImp The new implementation for the instance method
 * \param selector The selector of the instance method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newImp
       forInstanceMethod: (SEL)selector;

/**
 * Replaces an instance method with an instance method from another class.
 *
 * \param selector The selector of the instance method to replace
 * \param class_ The class from which the new instance method should be taken
 * \return The old implementation
 */
+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class_;

/**
 * Initializes an already allocated object.
 *
 * Derived classes may override this, but need to do self = [super init] before
 * they do any initialization themselves. init may never return nil, instead
 * an exception (for example OFInitializationFailed) should be thrown.
 *
 * \return An initialized object
 */
- init;

/**
 * \return The name of the object's class.
 */
- (OFString*)className;

/**
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the objects conforms to the specified protocol
 */
- (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \param selector The selector for which the method should be returned
 *
 * \return The implementation for the specified selector
 */
- (IMP)methodForSelector: (SEL)selector;

/**
 * \param selector The selector for which the type encoding should be returned
 *
 * \return The type encoding for the specified selector
 */
- (const char*)typeEncodingForSelector: (SEL)selector;

/**
 * Returns a description for the object.
 *
 * This is mostly for debugging purposes.
 */
- (OFString*)description;

/**
 * Adds a pointer to the object's memory pool.
 *
 * This is useful to add memory allocated by functions such as asprintf to the
 * pool so it gets free'd automatically when the object is deallocated.
 *
 * \param ptr A pointer to add to the memory pool
 */
- (void)addMemoryToPool: (void*)ptr;

/**
 * Allocates memory and stores it in the object's memory pool so it can be
 * free'd automatically when the object is deallocated.
 *
 * \param size The size of the memory to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryWithSize: (size_t)size;

/**
 * Allocates memory for the specified number of items and stores it in the
 * object's memory pool so it can be free'd automatically when the object is
 * deallocated.
 *
 * \param nItems The number of items to allocate
 * \param size The size of each item to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryForNItems: (size_t)nItems
		     withSize: (size_t)size;

/**
 * Resizes memory in the object's memory pool to the specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param size The new size for the memory chunk
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size;

/**
 * Resizes memory in the object's memory pool to the specific number of items of
 * the specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param nItems The number of items to resize to
 * \param size The size of each item to resize to
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nItems
	     withSize: (size_t)size;

/**
 * Frees allocated memory and removes it from the object's memory pool.
 * Does nothing if ptr is NULL.
 *
 * \param ptr A pointer to the allocated memory
 */
- (void)freeMemory: (void*)ptr;

/**
 * Deallocates the object and also frees all memory in its memory pool.
 *
 * It is also called when the retain count reaches zero.
 */
- (void)dealloc;

/**
 * If a garbage collector is added in the future, this method will be called
 * before it disposes of the object, for example to close files.
 */
- (void)finalize;
@end

/**
 * \brief A protocol for the creation of copies.
 */
@protocol OFCopying <OFObject>
/**
 * \return A copy of the object
 */
- copy;
@end

/**
 * \brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying <OFCopying>
/**
 * \return A mutable copy of the object
 */
- mutableCopy;
@end

/**
 * \brief A protocol for comparing objects.
 *
 * This protocol is implemented by objects that can be compared.
 */
@protocol OFComparing <OFObject>
/**
 * Compares the object with another object.
 *
 * \param object An object to compare the object to
 * \return The result of the comparison
 */
- (of_comparison_result_t)compare: (id)object;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern id objc_getProperty(id, SEL, ptrdiff_t, BOOL);
extern void objc_setProperty(id, SEL, ptrdiff_t, id, BOOL, BOOL);
extern size_t of_pagesize;
#ifdef __cplusplus
}
#endif
