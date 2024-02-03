/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFWRT.h"
#import "private.h"

#ifdef OF_HAVE_THREADS
# import "OFPlainMutex.h"
# define numSpinlocks 8	/* needs to be a power of 2 */
static OFSpinlock spinlocks[numSpinlocks];

static OF_INLINE size_t
spinlockSlot(id object)
{
	return ((size_t)((uintptr_t)object >> 4) & (numSpinlocks - 1));
}
#endif

struct Association {
	id object;
	objc_associationPolicy policy;
};

static struct objc_hashtable *hashtable;

static uint32_t
hash(const void *object)
{
	return (uint32_t)(uintptr_t)object;
}

static bool
equal(const void *object1, const void *object2)
{
	return (object1 == object2);
}

OF_CONSTRUCTOR()
{
	hashtable = objc_hashtable_new(hash, equal, 2);

#ifdef OF_HAVE_THREADS
	for (size_t i = 0; i < numSpinlocks; i++)
		if (OFSpinlockNew(&spinlocks[i]) != 0)
			OBJC_ERROR("Failed to create spinlocks!");
#endif
}

void
objc_setAssociatedObject(id object, const void *key, id value,
    objc_associationPolicy policy)
{
#ifdef OF_HAVE_THREADS
	size_t slot;
#endif

	switch (policy) {
	case OBJC_ASSOCIATION_ASSIGN:
		break;
	case OBJC_ASSOCIATION_RETAIN:
	case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
		value = [value retain];
		break;
	case OBJC_ASSOCIATION_COPY:
	case OBJC_ASSOCIATION_COPY_NONATOMIC:
		value = [value copy];
		break;
	default:
		/* Don't know what to do, so do nothing. */
		return;
	}

#ifdef OF_HAVE_THREADS
	slot = spinlockSlot(object);

	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		struct objc_hashtable *objectHashtable;
		struct Association *association;

		objectHashtable = objc_hashtable_get(hashtable, object);
		if (objectHashtable == NULL) {
			objectHashtable = objc_hashtable_new(hash, equal, 2);
			objc_hashtable_set(hashtable, object, objectHashtable);
		}

		association = objc_hashtable_get(objectHashtable, key);
		if (association != NULL) {
			switch (association->policy) {
			case OBJC_ASSOCIATION_RETAIN:
			case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
			case OBJC_ASSOCIATION_COPY:
			case OBJC_ASSOCIATION_COPY_NONATOMIC:
				[association->object release];
				break;
			default:
				break;
			}
		} else {
			association = malloc(sizeof(*association));
			if (association == NULL)
				OBJC_ERROR("Failed to allocate association!");

			objc_hashtable_set(objectHashtable, key, association);
		}

		association->policy = policy;
		association->object = value;
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif
}

id
objc_getAssociatedObject(id object, const void *key)
{
#ifdef OF_HAVE_THREADS
	size_t slot = spinlockSlot(object);

	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		struct objc_hashtable *objectHashtable;
		struct Association *association;

		objectHashtable = objc_hashtable_get(hashtable, object);
		if (objectHashtable == NULL)
			return nil;

		association = objc_hashtable_get(objectHashtable, key);
		if (association == NULL)
			return nil;

		switch (association->policy) {
		case OBJC_ASSOCIATION_RETAIN:
		case OBJC_ASSOCIATION_COPY:
			return [[association->object retain] autorelease];
		default:
			return association->object;
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif
}

void
objc_removeAssociatedObjects(id object)
{
#ifdef OF_HAVE_THREADS
	size_t slot = spinlockSlot(object);

	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		struct objc_hashtable *objectHashtable;

		objectHashtable = objc_hashtable_get(hashtable, object);
		if (objectHashtable == NULL)
			return;

		for (uint32_t i = 0; i < objectHashtable->size; i++) {
			struct Association *association;

			if (objectHashtable->data[i] == NULL ||
			    objectHashtable->data[i] == &objc_deletedBucket)
				continue;

			association = (struct Association *)
			    objectHashtable->data[i]->object;

			switch (association->policy) {
			case OBJC_ASSOCIATION_RETAIN:
			case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
			case OBJC_ASSOCIATION_COPY:
			case OBJC_ASSOCIATION_COPY_NONATOMIC:
				[association->object release];
				break;
			default:
				break;
			}

			free(association);
		}

		objc_hashtable_delete(hashtable, object);
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif
}
