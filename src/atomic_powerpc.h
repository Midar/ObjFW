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
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
of_atomic_int32_add(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE void *_Nullable
of_atomic_ptr_add(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return (void *)i;
}

static OF_INLINE int
of_atomic_int_sub(volatile int *_Nonnull p, int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
of_atomic_int32_sub(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE void *_Nullable
of_atomic_ptr_sub(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return (void *)i;
}

static OF_INLINE int
of_atomic_int_inc(volatile int *_Nonnull p)
{
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
of_atomic_int32_inc(volatile int32_t *_Nonnull p)
{
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int
of_atomic_int_dec(volatile int *_Nonnull p)
{
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
of_atomic_int32_dec(volatile int32_t *_Nonnull p)
{
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
of_atomic_int_or(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
of_atomic_int32_or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
of_atomic_int_and(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
of_atomic_int32_and(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
of_atomic_int_xor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
of_atomic_int32_xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE bool
of_atomic_int_cmpswap(volatile int *_Nonnull p, int o, int n)
{
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE bool
of_atomic_int32_cmpswap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE bool
of_atomic_ptr_cmpswap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE void
of_memory_barrier(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C2004AC /* lwsync */" ::: "memory"
	);
}

static OF_INLINE void
of_memory_barrier_acquire(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C2004AC /* lwsync */" ::: "memory"
	);
}

static OF_INLINE void
of_memory_barrier_release(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C2004AC /* lwsync */" ::: "memory"
	);
}
