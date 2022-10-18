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

#include "config.h"

#ifndef _XOPEN_SOURCE_EXTENDED
# define _XOPEN_SOURCE_EXTENDED
#endif
#define _HPUX_ALT_XOPEN_SOCKET_API

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFDatagramSocket.h"
#import "OFData.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFGetOptionFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

@implementation OFDatagramSocket
@synthesize delegate = _delegate;

+ (void)initialize
{
	if (self != [OFDatagramSocket class])
		return;

	if (!OFSocketInit())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (self.class == [OFDatagramSocket class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		_socket = OFInvalidSocketHandle;
		_canBlock = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_socket != OFInvalidSocketHandle)
		[self close];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (bool)canBlock
{
	return _canBlock;
}

- (void)setCanBlock: (bool)canBlock
{
#if defined(HAVE_FCNTL)
	int flags = fcntl(_socket, F_GETFL, 0);

	if (flags == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	if (canBlock)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl(_socket, F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	_canBlock = canBlock;
#elif defined(OF_WINDOWS)
	u_long v = !canBlock;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: OFSocketErrNo()];

	_canBlock = canBlock;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)setCanSendToBroadcastAddresses: (bool)canSendToBroadcastAddresses
{
	int v = canSendToBroadcastAddresses;

	if (setsockopt(_socket, SOL_SOCKET, SO_BROADCAST,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: OFSocketErrNo()];

#ifdef OF_WII
	_canSendToBroadcastAddresses = canSendToBroadcastAddresses;
#endif
}

- (bool)canSendToBroadcastAddresses
{
#ifndef OF_WII
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, SOL_SOCKET, SO_BROADCAST,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: OFSocketErrNo()];

	return v;
#else
	return _canSendToBroadcastAddresses;
#endif
}

- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (OFSocketAddress *)sender
{
	ssize_t ret;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	sender->length = (socklen_t)sizeof(sender->sockaddr);

#ifndef OF_WINDOWS
	if ((ret = recvfrom(_socket, buffer, length, 0,
	    (struct sockaddr *)&sender->sockaddr, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: OFSocketErrNo()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recvfrom(_socket, buffer, (int)length, 0,
	    (struct sockaddr *)&sender->sockaddr, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: OFSocketErrNo()];
#endif

	switch (((struct sockaddr *)&sender->sockaddr)->sa_family) {
	case AF_INET:
		sender->family = OFSocketAddressFamilyIPv4;
		break;
#ifdef OF_HAVE_IPV6
	case AF_INET6:
		sender->family = OFSocketAddressFamilyIPv6;
		break;
#endif
#ifdef OF_HAVE_UNIX_SOCKETS
	case AF_UNIX:
		sender->family = OFSocketAddressFamilyUNIX;
		break;
#endif
#ifdef OF_HAVE_IPX
	case AF_IPX:
		sender->family = OFSocketAddressFamilyIPX;
		break;
#endif
	default:
		sender->family = OFSocketAddressFamilyUnknown;
		break;
	}

	return ret;
}

- (void)asyncReceiveIntoBuffer: (void *)buffer length: (size_t)length
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncReceiveForDatagramSocket: self
						buffer: buffer
						length: length
						  mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
						 block: NULL
# endif
					      delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (OFDatagramSocketAsyncReceiveBlock)block
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode
			       block: block];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFDatagramSocketAsyncReceiveBlock)block
{
	[OFRunLoop of_addAsyncReceiveForDatagramSocket: self
						buffer: buffer
						length: length
						  mode: runLoopMode
						 block: block
					      delegate: nil];
}
#endif

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sendto(_socket, (void *)buffer, length, 0,
	    (struct sockaddr *)&receiver->sockaddr, receiver->length)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: OFSocketErrNo()];
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sendto(_socket, buffer, (int)length, 0,
	    (struct sockaddr *)&receiver->sockaddr, receiver->length)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: OFSocketErrNo()];
#endif

	if ((size_t)bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncSendForDatagramSocket: self
					       data: data
					   receiver: receiver
					       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					      block: NULL
# endif
					   delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
		block: (OFDatagramSocketAsyncSendDataBlock)block
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: OFDefaultRunLoopMode
		      block: block];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFDatagramSocketAsyncSendDataBlock)block
{
	[OFRunLoop of_addAsyncSendForDatagramSocket: self
					       data: data
					   receiver: receiver
					       mode: runLoopMode
					      block: block
					   delegate: nil];
}
#endif

- (void)cancelAsyncRequests
{
	[OFRunLoop of_cancelAsyncRequestsForObject: self
					      mode: OFDefaultRunLoopMode];
}

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == OFInvalidSocketHandle)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == OFInvalidSocketHandle)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (void)close
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}
@end
