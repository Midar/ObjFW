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

static OF_INLINE int
of_atomic_int_add(volatile int *_Nonnull p, int i)
{
	return (*p += i);
}

static OF_INLINE int32_t
of_atomic_int32_add(volatile int32_t *_Nonnull p, int32_t i)
{
	return (*p += i);
}

static OF_INLINE void *_Nullable
of_atomic_ptr_add(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return (*(char *volatile *)p += i);
}

static OF_INLINE int
of_atomic_int_sub(volatile int *_Nonnull p, int i)
{
	return (*p -= i);
}

static OF_INLINE int32_t
of_atomic_int32_sub(volatile int32_t *_Nonnull p, int32_t i)
{
	return (*p -= i);
}

static OF_INLINE void *_Nullable
of_atomic_ptr_sub(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return (*(char *volatile *)p -= i);
}

static OF_INLINE int
of_atomic_int_inc(volatile int *_Nonnull p)
{
	return ++*p;
}

static OF_INLINE int32_t
of_atomic_int32_inc(volatile int32_t *_Nonnull p)
{
	return ++*p;
}

static OF_INLINE int
of_atomic_int_dec(volatile int *_Nonnull p)
{
	return --*p;
}

static OF_INLINE int32_t
of_atomic_int32_dec(volatile int32_t *_Nonnull p)
{
	return --*p;
}

static OF_INLINE unsigned int
of_atomic_int_or(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p |= i);
}

static OF_INLINE uint32_t
of_atomic_int32_or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p |= i);
}

static OF_INLINE unsigned int
of_atomic_int_and(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p &= i);
}

static OF_INLINE uint32_t
of_atomic_int32_and(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p &= i);
}

static OF_INLINE unsigned int
of_atomic_int_xor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p ^= i);
}

static OF_INLINE uint32_t
of_atomic_int32_xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p ^= i);
}

static OF_INLINE bool
of_atomic_int_cmpswap(volatile int *_Nonnull p, int o, int n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE bool
of_atomic_int32_cmpswap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE bool
of_atomic_ptr_cmpswap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE void
of_memory_barrier(void)
{
	/* nop */
}

static OF_INLINE void
of_memory_barrier_acquire(void)
{
	/* nop */
}

static OF_INLINE void
of_memory_barrier_release(void)
{
	/* nop */
}
