/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#ifdef OF_WINDOWS
# include <windows.h>
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFString;
@class OFValue;

#define OFStackTraceSize 16

#if defined(OF_WINDOWS) && defined(OF_HAVE_SOCKETS)
# ifndef EADDRINUSE
#  define EADDRINUSE WSAEADDRINUSE
# endif
# ifndef EADDRNOTAVAIL
#  define EADDRNOTAVAIL WSAEADDRNOTAVAIL
# endif
# ifndef EAFNOSUPPORT
#  define EAFNOSUPPORT WSAEAFNOSUPPORT
# endif
# ifndef EALREADY
#  define EALREADY WSAEALREADY
# endif
# ifndef ECONNABORTED
#  define ECONNABORTED WSAECONNABORTED
# endif
# ifndef ECONNREFUSED
#  define ECONNREFUSED WSAECONNREFUSED
# endif
# ifndef ECONNRESET
#  define ECONNRESET WSAECONNRESET
# endif
# ifndef EDESTADDRREQ
#  define EDESTADDRREQ WSAEDESTADDRREQ
# endif
# ifndef EDQUOT
#  define EDQUOT WSAEDQUOT
# endif
# ifndef EHOSTDOWN
#  define EHOSTDOWN WSAEHOSTDOWN
# endif
# ifndef EHOSTUNREACH
#  define EHOSTUNREACH WSAEHOSTUNREACH
# endif
# ifndef EINPROGRESS
#  define EINPROGRESS WSAEINPROGRESS
# endif
# ifndef EISCONN
#  define EISCONN WSAEISCONN
# endif
# ifndef ELOOP
#  define ELOOP WSAELOOP
# endif
# ifndef EMSGSIZE
#  define EMSGSIZE WSAEMSGSIZE
# endif
# ifndef ENETDOWN
#  define ENETDOWN WSAENETDOWN
# endif
# ifndef ENETRESET
#  define ENETRESET WSAENETRESET
# endif
# ifndef ENETUNREACH
#  define ENETUNREACH WSAENETUNREACH
# endif
# ifndef ENOBUFS
#  define ENOBUFS WSAENOBUFS
# endif
# ifndef ENOPROTOOPT
#  define ENOPROTOOPT WSAENOPROTOOPT
# endif
# ifndef ENOTCONN
#  define ENOTCONN WSAENOTCONN
# endif
# ifndef ENOTSOCK
#  define ENOTSOCK WSAENOTSOCK
# endif
# ifndef EOPNOTSUPP
#  define EOPNOTSUPP WSAEOPNOTSUPP
# endif
# ifndef EPFNOSUPPORT
#  define EPFNOSUPPORT WSAEPFNOSUPPORT
# endif
# ifndef EPROCLIM
#  define EPROCLIM WSAEPROCLIM
# endif
# ifndef EPROTONOSUPPORT
#  define EPROTONOSUPPORT WSAEPROTONOSUPPORT
# endif
# ifndef EPROTOTYPE
#  define EPROTOTYPE WSAEPROTOTYPE
# endif
# ifndef EREMOTE
#  define EREMOTE WSAEREMOTE
# endif
# ifndef ESHUTDOWN
#  define ESHUTDOWN WSAESHUTDOWN
# endif
# ifndef ESOCKTNOSUPPORT
#  define ESOCKTNOSUPPORT WSAESOCKTNOSUPPORT
# endif
# ifndef ESTALE
#  define ESTALE WSAESTALE
# endif
# ifndef ETIMEDOUT
#  define ETIMEDOUT WSAETIMEDOUT
# endif
# ifndef ETOOMANYREFS
#  define ETOOMANYREFS WSAETOOMANYREFS
# endif
# ifndef EUSERS
#  define EUSERS WSAEUSERS
# endif
# ifndef EWOULDBLOCK
#  define EWOULDBLOCK WSAEWOULDBLOCK
# endif
#endif

#ifndef EWOULDBLOCK
# define EWOULDBLOCK EAGAIN
#endif

/**
 * @class OFException OFException.h ObjFW/OFException.h
 *
 * @brief The base class for all exceptions in ObjFW
 *
 * The OFException class is the base class for all exceptions in ObjFW, except
 * the OFAllocFailedException.
 */
@interface OFException: OFObject
{
	void *_stackTrace[OFStackTraceSize];
	OF_RESERVE_IVARS(OFException, 4)
}

/**
 * @brief Creates a new, autoreleased exception.
 *
 * @return A new, autoreleased exception
 */
+ (instancetype)exception;

/**
 * @brief Returns a description of the exception.
 *
 * @return A description of the exception
 */
- (OFString *)description;

/**
 * @brief Returns a stack trace of when the exception was created or `nil` if
 *	  no stack trace is available. The returned array contains OFValues
 *	  with @ref OFValue#pointerValue set to the address.
 *
 * @return The stack trace as array of addresses
 */
- (nullable OFArray OF_GENERIC(OFValue *) *)stackTraceAddresses;

/**
 * @brief Returns a stack trace of when the exception was created or `nil` if
 *	  no stack trace symbols are available.
 *
 * @return The stack trace as array of symbols
 */
- (nullable OFArray OF_GENERIC(OFString *) *)stackTraceSymbols;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString *OFStrError(int errNo);
#ifdef OF_WINDOWS
extern OFString *OFWindowsStatusToString(LSTATUS status);
#endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
