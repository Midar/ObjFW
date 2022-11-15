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

/* This file is automatically generated from amiga-library.xml */

#include "config.h"

#import "amiga-library.h"
#import "OFObject.h"
#import "OFStdIOStream.h"
#import "OFApplication.h"
#import "OFBlock.h"
#import "OFDNSResourceRecord.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFList.h"
#import "OFMethodSignature.h"
#import "OFOnce.h"
#import "OFPBKDF2.h"
#import "OFScrypt.h"
#import "OFSocket.h"
#import "OFTLSStream.h"
#import "OFStrPTime.h"
#import "OFString.h"
#import "OFZIPArchiveEntry.h"

extern struct Library *ObjFWBase;

#pragma GCC diagnostic ignored "-Warray-parameter"

bool
OFInit(unsigned int version, struct OFLibC *_Nonnull libc, FILE *_Nonnull *_Nonnull sF)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((bool (*)(unsigned int __asm__("d0"), struct OFLibC *_Nonnull __asm__("a0"), FILE *_Nonnull *_Nonnull __asm__("a1")))(((uintptr_t)ObjFWBase) - 30))(version, libc, sF);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((bool (*)(unsigned int, struct OFLibC *_Nonnull, FILE *_Nonnull *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 28))(version, libc, sF);
#endif
}

void *_Nullable
OFAllocMemory(size_t count, size_t size)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((void *_Nullable (*)(size_t __asm__("d0"), size_t __asm__("d1")))(((uintptr_t)ObjFWBase) - 36))(count, size);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((void *_Nullable (*)(size_t, size_t))*(void **)(((uintptr_t)ObjFWBase) - 34))(count, size);
#endif
}

void *_Nullable
OFAllocZeroedMemory(size_t count, size_t size)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((void *_Nullable (*)(size_t __asm__("d0"), size_t __asm__("d1")))(((uintptr_t)ObjFWBase) - 42))(count, size);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((void *_Nullable (*)(size_t, size_t))*(void **)(((uintptr_t)ObjFWBase) - 40))(count, size);
#endif
}

void *_Nullable
OFResizeMemory(void *_Nullable pointer, size_t count, size_t size)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((void *_Nullable (*)(void *_Nullable __asm__("a0"), size_t __asm__("d0"), size_t __asm__("d1")))(((uintptr_t)ObjFWBase) - 48))(pointer, count, size);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((void *_Nullable (*)(void *_Nullable, size_t, size_t))*(void **)(((uintptr_t)ObjFWBase) - 46))(pointer, count, size);
#endif
}

void
OFFreeMemory(void *_Nullable pointer)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(void *_Nullable __asm__("a0")))(((uintptr_t)ObjFWBase) - 54))(pointer);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(void *_Nullable))*(void **)(((uintptr_t)ObjFWBase) - 52))(pointer);
#endif
}

void
OFHashInit(unsigned long *_Nonnull hash)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(unsigned long *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 60))(hash);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(unsigned long *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 58))(hash);
#endif
}

uint16_t
OFRandom16()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint16_t (*)())(((uintptr_t)ObjFWBase) - 66))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint16_t (*)())*(void **)(((uintptr_t)ObjFWBase) - 64))();
#endif
}

uint32_t
OFRandom32()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint32_t (*)())(((uintptr_t)ObjFWBase) - 72))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint32_t (*)())*(void **)(((uintptr_t)ObjFWBase) - 70))();
#endif
}

uint64_t
OFRandom64()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint64_t (*)())(((uintptr_t)ObjFWBase) - 78))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint64_t (*)())*(void **)(((uintptr_t)ObjFWBase) - 76))();
#endif
}

unsigned long *_Nonnull
OFHashSeedRef()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((unsigned long *_Nonnull (*)())(((uintptr_t)ObjFWBase) - 84))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((unsigned long *_Nonnull (*)())*(void **)(((uintptr_t)ObjFWBase) - 82))();
#endif
}

OFStdIOStream *_Nonnull *_Nullable
OFStdInRef()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFStdIOStream *_Nonnull *_Nullable (*)())(((uintptr_t)ObjFWBase) - 90))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFStdIOStream *_Nonnull *_Nullable (*)())*(void **)(((uintptr_t)ObjFWBase) - 88))();
#endif
}

OFStdIOStream *_Nonnull *_Nullable
OFStdOutRef()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFStdIOStream *_Nonnull *_Nullable (*)())(((uintptr_t)ObjFWBase) - 96))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFStdIOStream *_Nonnull *_Nullable (*)())*(void **)(((uintptr_t)ObjFWBase) - 94))();
#endif
}

OFStdIOStream *_Nonnull *_Nullable
OFStdErrRef()
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFStdIOStream *_Nonnull *_Nullable (*)())(((uintptr_t)ObjFWBase) - 102))();
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFStdIOStream *_Nonnull *_Nullable (*)())*(void **)(((uintptr_t)ObjFWBase) - 100))();
#endif
}

void
OFLogV(OFConstantString *format, va_list arguments)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFConstantString *__asm__("a0"), va_list __asm__("a1")))(((uintptr_t)ObjFWBase) - 108))(format, arguments);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFConstantString *, va_list))*(void **)(((uintptr_t)ObjFWBase) - 106))(format, arguments);
#endif
}

int
OFApplicationMain(int *_Nonnull argc, char *_Nullable *_Nonnull *_Nonnull argv, id <OFApplicationDelegate> delegate)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((int (*)(int *_Nonnull __asm__("a0"), char *_Nullable *_Nonnull *_Nonnull __asm__("a1"), id <OFApplicationDelegate> __asm__("a2")))(((uintptr_t)ObjFWBase) - 114))(argc, argv, delegate);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((int (*)(int *_Nonnull, char *_Nullable *_Nonnull *_Nonnull, id <OFApplicationDelegate>))*(void **)(((uintptr_t)ObjFWBase) - 112))(argc, argv, delegate);
#endif
}

void *_Nullable
_Block_copy(const void *_Nullable block)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((void *_Nullable (*)(const void *_Nullable __asm__("a0")))(((uintptr_t)ObjFWBase) - 120))(block);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((void *_Nullable (*)(const void *_Nullable))*(void **)(((uintptr_t)ObjFWBase) - 118))(block);
#endif
}

void
_Block_release(const void *_Nullable block)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(const void *_Nullable __asm__("a0")))(((uintptr_t)ObjFWBase) - 126))(block);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(const void *_Nullable))*(void **)(((uintptr_t)ObjFWBase) - 124))(block);
#endif
}

OFString *_Nonnull
OFDNSClassName(OFDNSClass DNSClass)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(OFDNSClass __asm__("d0")))(((uintptr_t)ObjFWBase) - 132))(DNSClass);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(OFDNSClass))*(void **)(((uintptr_t)ObjFWBase) - 130))(DNSClass);
#endif
}

OFString *_Nonnull
OFDNSRecordTypeName(OFDNSRecordType recordType)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(OFDNSRecordType __asm__("d0")))(((uintptr_t)ObjFWBase) - 138))(recordType);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(OFDNSRecordType))*(void **)(((uintptr_t)ObjFWBase) - 136))(recordType);
#endif
}

OFDNSClass
OFDNSClassParseName(OFString *_Nonnull string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFDNSClass (*)(OFString *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 144))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFDNSClass (*)(OFString *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 142))(string);
#endif
}

OFDNSRecordType
OFDNSRecordTypeParseName(OFString *_Nonnull string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFDNSRecordType (*)(OFString *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 150))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFDNSRecordType (*)(OFString *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 148))(string);
#endif
}

const char *_Nullable
OFHTTPRequestMethodName(OFHTTPRequestMethod method)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((const char *_Nullable (*)(OFHTTPRequestMethod __asm__("d0")))(((uintptr_t)ObjFWBase) - 156))(method);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((const char *_Nullable (*)(OFHTTPRequestMethod))*(void **)(((uintptr_t)ObjFWBase) - 154))(method);
#endif
}

OFHTTPRequestMethod
OFHTTPRequestMethodParseName(OFString *string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFHTTPRequestMethod (*)(OFString *__asm__("a0")))(((uintptr_t)ObjFWBase) - 162))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFHTTPRequestMethod (*)(OFString *))*(void **)(((uintptr_t)ObjFWBase) - 160))(string);
#endif
}

OFString *_Nonnull
OFHTTPStatusCodeString(short code)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(short __asm__("d0")))(((uintptr_t)ObjFWBase) - 168))(code);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(short))*(void **)(((uintptr_t)ObjFWBase) - 166))(code);
#endif
}

OFListItem _Nullable
OFListItemNext(OFListItem _Nonnull listItem)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFListItem _Nullable (*)(OFListItem _Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 174))(listItem);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFListItem _Nullable (*)(OFListItem _Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 172))(listItem);
#endif
}

OFListItem _Nullable
OFListItemPrevious(OFListItem _Nonnull listItem)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFListItem _Nullable (*)(OFListItem _Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 180))(listItem);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFListItem _Nullable (*)(OFListItem _Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 178))(listItem);
#endif
}

id _Nonnull
OFListItemObject(OFListItem _Nonnull listItem)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((id _Nonnull (*)(OFListItem _Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 186))(listItem);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((id _Nonnull (*)(OFListItem _Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 184))(listItem);
#endif
}

size_t
OFSizeOfTypeEncoding(const char *type)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((size_t (*)(const char *__asm__("a0")))(((uintptr_t)ObjFWBase) - 192))(type);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((size_t (*)(const char *))*(void **)(((uintptr_t)ObjFWBase) - 190))(type);
#endif
}

size_t
OFAlignmentOfTypeEncoding(const char *type)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((size_t (*)(const char *__asm__("a0")))(((uintptr_t)ObjFWBase) - 198))(type);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((size_t (*)(const char *))*(void **)(((uintptr_t)ObjFWBase) - 196))(type);
#endif
}

void
OFOnce(OFOnceControl *_Nonnull control, OFOnceFunction _Nonnull func)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFOnceControl *_Nonnull __asm__("a0"), OFOnceFunction _Nonnull __asm__("a1")))(((uintptr_t)ObjFWBase) - 204))(control, func);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFOnceControl *_Nonnull, OFOnceFunction _Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 202))(control, func);
#endif
}

void
OFPBKDF2Wrapper(const OFPBKDF2Parameters *_Nonnull parameters)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(const OFPBKDF2Parameters *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 210))(parameters);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(const OFPBKDF2Parameters *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 208))(parameters);
#endif
}

void
OFScryptWrapper(const OFScryptParameters *_Nonnull parameters)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(const OFScryptParameters *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 216))(parameters);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(const OFScryptParameters *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 214))(parameters);
#endif
}

void
OFSalsa20_8Core(uint32_t *_Nonnull buffer)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(uint32_t *_Nonnull __asm__("a0")))(((uintptr_t)ObjFWBase) - 222))(buffer);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(uint32_t *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 220))(buffer);
#endif
}

void
OFScryptBlockMix(uint32_t *_Nonnull output, const uint32_t *_Nonnull input, size_t blockSize)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(uint32_t *_Nonnull __asm__("a0"), const uint32_t *_Nonnull __asm__("a1"), size_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 228))(output, input, blockSize);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(uint32_t *_Nonnull, const uint32_t *_Nonnull, size_t))*(void **)(((uintptr_t)ObjFWBase) - 226))(output, input, blockSize);
#endif
}

void
OFScryptROMix(uint32_t *buffer, size_t blockSize, size_t costFactor, uint32_t *tmp)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(uint32_t *__asm__("a0"), size_t __asm__("d0"), size_t __asm__("d1"), uint32_t *__asm__("a1")))(((uintptr_t)ObjFWBase) - 234))(buffer, blockSize, costFactor, tmp);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(uint32_t *, size_t, size_t, uint32_t *))*(void **)(((uintptr_t)ObjFWBase) - 232))(buffer, blockSize, costFactor, tmp);
#endif
}

OFSocketAddress
OFSocketAddressParseIP(OFString *IP, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(OFString *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 240))(IP, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(OFString *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 238))(IP, port);
#endif
}

OFSocketAddress
OFSocketAddressParseIPv4(OFString *IP, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(OFString *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 246))(IP, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(OFString *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 244))(IP, port);
#endif
}

OFSocketAddress
OFSocketAddressParseIPv6(OFString *IP, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(OFString *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 252))(IP, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(OFString *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 250))(IP, port);
#endif
}

OFSocketAddress
OFSocketAddressMakeUNIX(OFString *path)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(OFString *__asm__("a0")))(((uintptr_t)ObjFWBase) - 258))(path);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(OFString *))*(void **)(((uintptr_t)ObjFWBase) - 256))(path);
#endif
}

OFSocketAddress
OFSocketAddressMakeIPX(uint32_t network, const unsigned char *node, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(uint32_t __asm__("d0"), const unsigned char *__asm__("a0"), uint16_t __asm__("d1")))(((uintptr_t)ObjFWBase) - 264))(network, node, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(uint32_t, const unsigned char *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 262))(network, node, port);
#endif
}

OFSocketAddress
OFSocketAddressMakeAppleTalk(uint16_t network, uint8_t node, uint8_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFSocketAddress (*)(uint16_t __asm__("d0"), uint8_t __asm__("d1"), uint8_t __asm__("d2")))(((uintptr_t)ObjFWBase) - 270))(network, node, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFSocketAddress (*)(uint16_t, uint8_t, uint8_t))*(void **)(((uintptr_t)ObjFWBase) - 268))(network, node, port);
#endif
}

bool
OFSocketAddressEqual(const OFSocketAddress *address1, const OFSocketAddress *address2)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((bool (*)(const OFSocketAddress *__asm__("a0"), const OFSocketAddress *__asm__("a1")))(((uintptr_t)ObjFWBase) - 276))(address1, address2);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((bool (*)(const OFSocketAddress *, const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 274))(address1, address2);
#endif
}

unsigned long
OFSocketAddressHash(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((unsigned long (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 282))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((unsigned long (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 280))(address);
#endif
}

OFString *_Nonnull
OFSocketAddressString(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 288))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 286))(address);
#endif
}

void
OFSocketAddressSetIPPort(OFSocketAddress *address, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 294))(address, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 292))(address, port);
#endif
}

uint16_t
OFSocketAddressIPPort(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint16_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 300))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint16_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 298))(address);
#endif
}

OFString *
OFSocketAddressUNIXPath(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *(*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 306))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *(*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 304))(address);
#endif
}

void
OFSocketAddressSetIPXNetwork(OFSocketAddress *address, uint32_t network)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint32_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 312))(address, network);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint32_t))*(void **)(((uintptr_t)ObjFWBase) - 310))(address, network);
#endif
}

uint32_t
OFSocketAddressIPXNetwork(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint32_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 318))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint32_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 316))(address);
#endif
}

void
OFSocketAddressSetIPXNode(OFSocketAddress *address, const unsigned char *node)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), const unsigned char *__asm__("a1")))(((uintptr_t)ObjFWBase) - 324))(address, node);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, const unsigned char *))*(void **)(((uintptr_t)ObjFWBase) - 322))(address, node);
#endif
}

void
OFSocketAddressGetIPXNode(const OFSocketAddress *address, unsigned char *_Nonnull node)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(const OFSocketAddress *__asm__("a0"), unsigned char *_Nonnull __asm__("a1")))(((uintptr_t)ObjFWBase) - 330))(address, node);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(const OFSocketAddress *, unsigned char *_Nonnull))*(void **)(((uintptr_t)ObjFWBase) - 328))(address, node);
#endif
}

void
OFSocketAddressSetIPXPort(OFSocketAddress *address, uint16_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 336))(address, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 334))(address, port);
#endif
}

uint16_t
OFSocketAddressIPXPort(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint16_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 342))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint16_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 340))(address);
#endif
}

void
OFSocketAddressSetAppleTalkNetwork(OFSocketAddress *address, uint16_t network)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 348))(address, network);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 346))(address, network);
#endif
}

uint16_t
OFSocketAddressAppleTalkNetwork(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint16_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 354))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint16_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 352))(address);
#endif
}

void
OFSocketAddressSetAppleTalkNode(OFSocketAddress *address, uint8_t node)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint8_t __asm__("(nil)")))(((uintptr_t)ObjFWBase) - 360))(address, node);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint8_t))*(void **)(((uintptr_t)ObjFWBase) - 358))(address, node);
#endif
}

uint8_t
OFSocketAddressAppleTalkNode(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint8_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 366))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint8_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 364))(address);
#endif
}

void
OFSocketAddressSetAppleTalkPort(OFSocketAddress *address, uint8_t port)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	((void (*)(OFSocketAddress *__asm__("a0"), uint8_t __asm__("(nil)")))(((uintptr_t)ObjFWBase) - 372))(address, port);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	__extension__ ((void (*)(OFSocketAddress *, uint8_t))*(void **)(((uintptr_t)ObjFWBase) - 370))(address, port);
#endif
}

uint8_t
OFSocketAddressAppleTalkPort(const OFSocketAddress *address)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((uint8_t (*)(const OFSocketAddress *__asm__("a0")))(((uintptr_t)ObjFWBase) - 378))(address);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((uint8_t (*)(const OFSocketAddress *))*(void **)(((uintptr_t)ObjFWBase) - 376))(address);
#endif
}

OFString *
OFTLSStreamErrorCodeDescription(OFTLSStreamErrorCode errorCode)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *(*)(OFTLSStreamErrorCode __asm__("d0")))(((uintptr_t)ObjFWBase) - 384))(errorCode);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *(*)(OFTLSStreamErrorCode))*(void **)(((uintptr_t)ObjFWBase) - 382))(errorCode);
#endif
}

const char *_Nullable
OFStrPTime(const char *buffer, const char *format, struct tm *tm, int16_t *_Nullable tz)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((const char *_Nullable (*)(const char *__asm__("a0"), const char *__asm__("a1"), struct tm *__asm__("a2"), int16_t *_Nullable __asm__("a3")))(((uintptr_t)ObjFWBase) - 390))(buffer, format, tm, tz);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((const char *_Nullable (*)(const char *, const char *, struct tm *, int16_t *_Nullable))*(void **)(((uintptr_t)ObjFWBase) - 388))(buffer, format, tm, tz);
#endif
}

OFStringEncoding
OFStringEncodingParseName(OFString *string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFStringEncoding (*)(OFString *__asm__("a0")))(((uintptr_t)ObjFWBase) - 396))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFStringEncoding (*)(OFString *))*(void **)(((uintptr_t)ObjFWBase) - 394))(string);
#endif
}

OFString *_Nullable
OFStringEncodingName(OFStringEncoding encoding)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nullable (*)(OFStringEncoding __asm__("d0")))(((uintptr_t)ObjFWBase) - 402))(encoding);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nullable (*)(OFStringEncoding))*(void **)(((uintptr_t)ObjFWBase) - 400))(encoding);
#endif
}

size_t
OFUTF16StringLength(const OFChar16 *string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((size_t (*)(const OFChar16 *__asm__("a0")))(((uintptr_t)ObjFWBase) - 408))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((size_t (*)(const OFChar16 *))*(void **)(((uintptr_t)ObjFWBase) - 406))(string);
#endif
}

size_t
OFUTF32StringLength(const OFChar32 *string)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((size_t (*)(const OFChar32 *__asm__("a0")))(((uintptr_t)ObjFWBase) - 414))(string);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((size_t (*)(const OFChar32 *))*(void **)(((uintptr_t)ObjFWBase) - 412))(string);
#endif
}

OFString *_Nonnull
OFZIPArchiveEntryVersionToString(uint16_t version)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(uint16_t __asm__("d0")))(((uintptr_t)ObjFWBase) - 420))(version);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(uint16_t))*(void **)(((uintptr_t)ObjFWBase) - 418))(version);
#endif
}

OFString *_Nonnull
OFZIPArchiveEntryCompressionMethodName(OFZIPArchiveEntryCompressionMethod compressionMethod)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((OFString *_Nonnull (*)(OFZIPArchiveEntryCompressionMethod __asm__("d0")))(((uintptr_t)ObjFWBase) - 426))(compressionMethod);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((OFString *_Nonnull (*)(OFZIPArchiveEntryCompressionMethod))*(void **)(((uintptr_t)ObjFWBase) - 424))(compressionMethod);
#endif
}

size_t
OFZIPArchiveEntryExtraFieldFind(OFData *extraField, OFZIPArchiveEntryExtraFieldTag tag, uint16_t *size)
{
#if defined(OF_AMIGAOS_M68K)
	register struct Library *a6 __asm__("a6") = ObjFWBase;
	(void)a6;
	return ((size_t (*)(OFData *__asm__("a0"), OFZIPArchiveEntryExtraFieldTag __asm__("d0"), uint16_t *__asm__("a1")))(((uintptr_t)ObjFWBase) - 432))(extraField, tag, size);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r"(ObjFWBase) : "r12"
	);

	return __extension__ ((size_t (*)(OFData *, OFZIPArchiveEntryExtraFieldTag, uint16_t *))*(void **)(((uintptr_t)ObjFWBase) - 430))(extraField, tag, size);
#endif
}
