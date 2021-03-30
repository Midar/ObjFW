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
#import "OFCollection.h"
#import "OFEnumerator.h"
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

typedef struct of_list_object_t of_list_object_t;
/**
 * @struct of_list_object_t OFList.h ObjFW/OFList.h
 *
 * @brief A list object.
 *
 * A struct that contains a pointer to the next list object, the previous list
 * object and the object.
 */
struct of_list_object_t {
	/** A pointer to the next list object in the list */
	of_list_object_t *_Nullable next;
	/** A pointer to the previous list object in the list */
	of_list_object_t *_Nullable previous;
	/** The object for the list object */
	id __unsafe_unretained object;
};

/**
 * @class OFList OFList.h ObjFW/OFList.h
 *
 * @brief A class which provides easy to use double-linked lists.
 */
@interface OFList OF_GENERIC(ObjectType): OFObject <OFCopying, OFCollection,
    OFSerialization>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
{
	of_list_object_t *_Nullable _firstListObject;
	of_list_object_t *_Nullable _lastListObject;
	size_t _count;
	unsigned long  _mutations;
	OF_RESERVE_IVARS(OFList, 4)
}

/**
 * @brief The first list object of the list.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    of_list_object_t *firstListObject;

/**
 * @brief The first object of the list or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType firstObject;

/**
 * @brief The last list object of the list.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    of_list_object_t *lastListObject;

/**
 * @brief The last object of the list or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType lastObject;

/**
 * @brief Creates a new OFList.
 *
 * @return A new autoreleased OFList
 */
+ (instancetype)list;

/**
 * @brief Appends an object to the list.
 *
 * @param object The object to append
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t *)appendObject: (ObjectType)object;

/**
 * @brief Prepends an object to the list.
 *
 * @param object The object to prepend
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t *)prependObject: (ObjectType)object;

/**
 * @brief Inserts an object before another list object.
 *
 * @param object The object to insert
 * @param listObject The of_list_object_t of the object before which it should
 *	  be inserted
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t *)insertObject: (ObjectType)object
		  beforeListObject: (of_list_object_t *)listObject;

/**
 * @brief Inserts an object after another list object.
 *
 * @param object The object to insert
 * @param listObject The of_list_object_t of the object after which it should be
 *	  inserted
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t *)insertObject: (ObjectType)object
		   afterListObject: (of_list_object_t *)listObject;

/**
 * @brief Removes the object with the specified list object from the list.
 *
 * @param listObject The list object returned by append / prepend
 */
- (void)removeListObject: (of_list_object_t *)listObject;

/**
 * @brief Checks whether the list contains an object equal to the specified
 *	  object.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/**
 * @brief Checks whether the list contains an object with the specified address.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains an object with the specified
 *	   address
 */
- (bool)containsObjectIdenticalTo: (ObjectType)object;

/**
 * @brief Removes all objects from the list.
 */
- (void)removeAllObjects;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
