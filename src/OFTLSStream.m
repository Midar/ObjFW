/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFTLSStream.h"
#import "OFDate.h"

#import "OFNotImplementedException.h"
#import "OFTLSHandshakeFailedException.h"

@interface OFTLSStreamHandshakeDelegate: OFObject <OFTLSStreamDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

Class OFTLSStreamImplementation = Nil;
static const OFRunLoopMode handshakeRunLoopMode =
    @"OFTLSStreamHandshakeRunLoopMode";

/*
 * References to exceptions. This is needed because they are only used by
 * subclasses that are in a different library.
 */
void OF_VISIBILITY_HIDDEN
_references_to_exceptions_of_OFTLSStream(void)
{
	_OFTLSHandshakeFailedException_reference = 1;
}

OFString *
OFTLSStreamErrorCodeDescription(OFTLSStreamErrorCode errorCode)
{
	switch (errorCode) {
	case OFTLSStreamErrorCodeInitializationFailed:
		return @"Initialization of TLS context failed";
	case OFTLSStreamErrorCodeCertificateVerificationFailed:
		return @"Verification of the certificate failed";
	case OFTLSStreamErrorCodeCertificateIssuerUntrusted:
		return @"The certificate has an untrusted or unknown issuer";
	case OFTLSStreamErrorCodeCertificateNameMismatch:
		return @"The certificate is for a different name";
	case OFTLSStreamErrorCodeCertificatedExpired:
		return @"The certificate has expired or is not yet valid";
	case OFTLSStreamErrorCodeCertificateRevoked:
		return @"The certificate has been revoked";
	default:
		return @"Unknown error";
	}
}

@implementation OFTLSStreamHandshakeDelegate
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

-		       (void)stream: (OFTLSStream *)stream
  didPerformClientHandshakeWithHost: (OFString *)host
			  exception: (id)exception
{
	_done = true;
	_exception = [exception retain];
}
@end

@implementation OFTLSStream
@synthesize underlyingStream = _underlyingStream;
@dynamic delegate;
@synthesize verifiesCertificates = _verifiesCertificates;

+ (instancetype)alloc
{
	if (self == [OFTLSStream class]) {
		if (OFTLSStreamImplementation != Nil)
			return [OFTLSStreamImplementation alloc];

		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
	}

	return [super alloc];
}

+ (instancetype)streamWithStream: (OFStream <OFReadyForReadingObserving,
				       OFReadyForWritingObserving> *)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				     OFReadyForWritingObserving> *)stream
{
	self = [super init];

	@try {
		_underlyingStream = [stream retain];
		_verifiesCertificates = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_underlyingStream release];

	[super dealloc];
}

- (void)close
{
	[_underlyingStream release];
	_underlyingStream = nil;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)lowlevelIsAtEndOfStream
{
	return _underlyingStream.atEndOfStream;
}

- (int)fileDescriptorForReading
{
	return _underlyingStream.fileDescriptorForReading;
}

- (int)fileDescriptorForWriting
{
	return _underlyingStream.fileDescriptorForWriting;
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
{
	[self asyncPerformClientHandshakeWithHost: host
				      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)performClientHandshakeWithHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	id <OFTLSStreamDelegate> delegate = _delegate;
	OFTLSStreamHandshakeDelegate *handshakeDelegate =
	    [[[OFTLSStreamHandshakeDelegate alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	_delegate = handshakeDelegate;
	[self asyncPerformClientHandshakeWithHost: host
				      runLoopMode: handshakeRunLoopMode];

	while (!handshakeDelegate->_done)
		[runLoop runMode: handshakeRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: handshakeRunLoopMode beforeDate: [OFDate date]];

	_delegate = delegate;

	if (handshakeDelegate->_exception != nil)
		@throw handshakeDelegate->_exception;

	objc_autoreleasePoolPop(pool);
}
@end
