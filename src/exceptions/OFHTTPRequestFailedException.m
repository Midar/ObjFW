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

#include "config.h"

#import "OFHTTPRequestFailedException.h"
#import "OFString.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"

@implementation OFHTTPRequestFailedException
@synthesize request = _request, response = _response;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithRequest: (OFHTTPRequest *)request
			    response: (OFHTTPResponse *)response
{
	return [[[self alloc] initWithRequest: request
				     response: response] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRequest: (OFHTTPRequest *)request
		       response: (OFHTTPResponse *)response
{
	self = [super init];

	_request = [request retain];
	_response = [response retain];

	return self;
}

- (void)dealloc
{
	[_request release];
	[_response release];

	[super dealloc];
}

- (OFString *)description
{
	const char *method = of_http_request_method_to_string(_request.method);

	return [OFString stringWithFormat:
	    @"An HTTP %s request with URL %@ failed with code %hd!", method,
	    _request.URL, _response.statusCode];
}
@end
