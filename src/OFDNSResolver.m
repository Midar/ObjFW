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

#include <string.h>

#import "OFDNSResolver.h"
#import "OFArray.h"
#import "OFDNSQuery.h"
#import "OFDNSResolverSettings.h"
#import "OFDNSResponse.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFHostAddressResolver.h"
#import "OFNumber.h"
#import "OFPair.h"
#import "OFString.h"
#import "OFTCPSocket.h"
#import "OFTimer.h"
#import "OFUDPSocket.h"
#import "OFUDPSocket+Private.h"

#import "OFDNSQueryFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

#ifndef SOCK_DNS
# define SOCK_DNS 0
#endif

#define BUFFER_LENGTH OF_DNS_RESOLVER_BUFFER_LENGTH
#define MAX_DNS_RESPONSE_LENGTH 65536

/*
 * RFC 1035 doesn't specify if pointers to pointers are allowed, and if so how
 * many. Since it's unspecified, we have to assume that it might happen, but we
 * also want to limit it to avoid DoS. Limiting it to 16 levels of pointers and
 * immediately rejecting pointers to itself seems like a fair balance.
 */
#define MAX_ALLOWED_POINTERS 16

#define CNAME_RECURSION 3

@interface OFDNSResolver () <OFUDPSocketDelegate, OFTCPSocketDelegate>
- (void)of_contextTimedOut: (OFDNSResolverContext *)context;
@end

OF_DIRECT_MEMBERS
@interface OFDNSResolverContext: OFObject
{
@public
	OFDNSQuery *_query;
	OFNumber *_ID;
	OFDNSResolverSettings *_settings;
	size_t _nameServersIndex;
	unsigned int _attempt;
	id <OFDNSResolverQueryDelegate> _delegate;
	OFData *_queryData;
	of_socket_address_t _usedNameServer;
	OFTCPSocket *_TCPSocket;
	OFMutableData *_TCPQueryData;
	void *_TCPBuffer;
	size_t _responseLength;
	OFTimer *_cancelTimer;
}

- (instancetype)initWithQuery: (OFDNSQuery *)query
			   ID: (OFNumber *)ID
		     settings: (OFDNSResolverSettings *)settings
		     delegate: (id <OFDNSResolverQueryDelegate>)delegate;
@end

static OFString *
parseString(const unsigned char *buffer, size_t length, size_t *i)
{
	uint8_t stringLength;
	OFString *string;

	if (*i >= length)
		@throw [OFTruncatedDataException exception];

	stringLength = buffer[(*i)++];

	if (*i + stringLength > length)
		@throw [OFTruncatedDataException exception];

	string = [OFString stringWithUTF8String: (char *)&buffer[*i]
					 length: stringLength];
	*i += stringLength;

	return string;
}

static OFString *
parseName(const unsigned char *buffer, size_t length, size_t *i,
    uint_fast8_t pointerLevel)
{
	OFMutableArray *components = [OFMutableArray array];
	uint8_t componentLength;

	do {
		OFString *component;

		if (*i >= length)
			@throw [OFTruncatedDataException exception];

		componentLength = buffer[(*i)++];

		if (componentLength & 0xC0) {
			size_t j;
			OFString *suffix;

			if (pointerLevel == 0)
				@throw [OFInvalidServerReplyException
				    exception];

			if (*i >= length)
				@throw [OFTruncatedDataException exception];

			j = ((componentLength & 0x3F) << 8) | buffer[(*i)++];

			if (j == *i - 2)
				/* Pointing to itself?! */
				@throw [OFInvalidServerReplyException
				    exception];

			suffix = parseName(buffer, length, &j,
			    pointerLevel - 1);

			if (components.count == 0)
				return suffix;
			else {
				[components addObject: suffix];
				return [components
				    componentsJoinedByString: @"."];
			}
		}

		if (*i + componentLength > length)
			@throw [OFTruncatedDataException exception];

		component = [OFString stringWithUTF8String: (char *)&buffer[*i]
						    length: componentLength];
		*i += componentLength;

		[components addObject: component];
	} while (componentLength > 0);

	return [components componentsJoinedByString: @"."];
}

static OF_KINDOF(OFDNSResourceRecord *)
parseResourceRecord(OFString *name, of_dns_class_t DNSClass,
    of_dns_record_type_t recordType, uint32_t TTL, const unsigned char *buffer,
    size_t length, size_t i, uint16_t dataLength)
{
	if (recordType == OF_DNS_RECORD_TYPE_A && DNSClass == OF_DNS_CLASS_IN) {
		of_socket_address_t address;

		if (dataLength != 4)
			@throw [OFInvalidServerReplyException exception];

		memset(&address, 0, sizeof(address));
		address.family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
		address.length = sizeof(address.sockaddr.in);

		address.sockaddr.in.sin_family = AF_INET;
		memcpy(&address.sockaddr.in.sin_addr.s_addr, buffer + i, 4);

		return [[[OFADNSResourceRecord alloc]
		    initWithName: name
			 address: &address
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_NS) {
		size_t j = i;
		OFString *authoritativeHost = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFNSDNSResourceRecord alloc]
			 initWithName: name
			     DNSClass: DNSClass
		    authoritativeHost: authoritativeHost
				  TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_CNAME) {
		size_t j = i;
		OFString *alias = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFCNAMEDNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
			   alias: alias
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_SOA) {
		size_t j = i;
		OFString *primaryNameServer = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);
		OFString *responsiblePerson;
		uint32_t serialNumber, refreshInterval, retryInterval;
		uint32_t expirationInterval, minTTL;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		responsiblePerson = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (dataLength - (j - i) != 20)
			@throw [OFInvalidServerReplyException exception];

		serialNumber = (buffer[j] << 24) | (buffer[j + 1] << 16) |
		    (buffer[j + 2] << 8) | buffer[j + 3];
		refreshInterval = (buffer[j + 4] << 24) |
		    (buffer[j + 5] << 16) | (buffer[j + 6] << 8) |
		    buffer[j + 7];
		retryInterval = (buffer[j + 8] << 24) | (buffer[j + 9] << 16) |
		    (buffer[j + 10] << 8) | buffer[j + 11];
		expirationInterval = (buffer[j + 12] << 24) |
		    (buffer[j + 13] << 16) | (buffer[j + 14] << 8) |
		    buffer[j + 15];
		minTTL = (buffer[j + 16] << 24) | (buffer[j + 17] << 16) |
		    (buffer[j + 18] << 8) | buffer[j + 19];

		return [[[OFSOADNSResourceRecord alloc]
			  initWithName: name
			      DNSClass: DNSClass
		     primaryNameServer: primaryNameServer
		     responsiblePerson: responsiblePerson
			  serialNumber: serialNumber
		       refreshInterval: refreshInterval
			 retryInterval: retryInterval
		    expirationInterval: expirationInterval
				minTTL: minTTL
				   TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_PTR) {
		size_t j = i;
		OFString *domainName = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFPTRDNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
		      domainName: domainName
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_HINFO) {
		size_t j = i;
		OFString *CPU = parseString(buffer, length, &j);
		OFString *OS;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		OS = parseString(buffer, length, &j);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFHINFODNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
			     CPU: CPU
			      OS: OS
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_MX) {
		uint16_t preference;
		size_t j;
		OFString *mailExchange;

		if (dataLength < 2)
			@throw [OFInvalidServerReplyException exception];

		preference = (buffer[i] << 8) | buffer[i + 1];

		j = i + 2;
		mailExchange = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFMXDNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
		      preference: preference
		    mailExchange: mailExchange
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_TXT) {
		OFMutableArray *textStrings = [OFMutableArray array];

		while (dataLength > 0) {
			uint_fast8_t stringLength = buffer[i++];
			dataLength--;

			if (stringLength > dataLength)
				@throw [OFInvalidServerReplyException
				    exception];

			[textStrings addObject:
			    [OFData dataWithItems: buffer + i
					    count: stringLength]];

			i += stringLength;
			dataLength -= stringLength;
		}

		[textStrings makeImmutable];

		return [[[OFTXTDNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
		     textStrings: textStrings
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_RP) {
		size_t j = i;
		OFString *mailbox = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);
		OFString *TXTDomainName;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		TXTDomainName = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFRPDNSResourceRecord alloc]
		     initWithName: name
			 DNSClass: DNSClass
			  mailbox: mailbox
		    TXTDomainName: TXTDomainName
			      TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_AAAA &&
	    DNSClass == OF_DNS_CLASS_IN) {
		of_socket_address_t address;

		if (dataLength != 16)
			@throw [OFInvalidServerReplyException exception];

		memset(&address, 0, sizeof(address));
		address.family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
		address.length = sizeof(address.sockaddr.in6);

#ifdef AF_INET6
		address.sockaddr.in6.sin6_family = AF_INET6;
#else
		address.sockaddr.in6.sin6_family = AF_UNSPEC;
#endif
		memcpy(address.sockaddr.in6.sin6_addr.s6_addr, buffer + i, 16);

		return [[[OFAAAADNSResourceRecord alloc]
		    initWithName: name
			 address: &address
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RECORD_TYPE_SRV &&
	    DNSClass == OF_DNS_CLASS_IN) {
		uint16_t priority, weight, port;
		size_t j;
		OFString *target;

		if (dataLength < 6)
			@throw [OFInvalidServerReplyException exception];

		priority = (buffer[i] << 8) | buffer[i + 1];
		weight = (buffer[i + 2] << 8) | buffer[i + 3];
		port = (buffer[i + 4] << 8) | buffer[i + 5];

		j = i + 6;
		target = parseName(buffer, length, &j, MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFSRVDNSResourceRecord alloc]
		    initWithName: name
			priority: priority
			  weight: weight
			  target: target
			    port: port
			     TTL: TTL] autorelease];
	} else
		return [[[OFDNSResourceRecord alloc]
		    initWithName: name
			DNSClass: DNSClass
		      recordType: recordType
			     TTL: TTL] autorelease];
}

static OFDictionary *
parseSection(const unsigned char *buffer, size_t length, size_t *i,
    uint_fast16_t count)
{
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	OFEnumerator OF_GENERIC(OFMutableArray *) *objectEnumerator;
	OFMutableArray *array;

	for (uint_fast16_t j = 0; j < count; j++) {
		OFString *name = parseName(buffer, length, i,
		    MAX_ALLOWED_POINTERS);
		of_dns_class_t DNSClass;
		of_dns_record_type_t recordType;
		uint32_t TTL;
		uint16_t dataLength;
		OFDNSResourceRecord *record;

		if (*i + 10 > length)
			@throw [OFTruncatedDataException exception];

		recordType = (buffer[*i] << 16) | buffer[*i + 1];
		DNSClass = (buffer[*i + 2] << 16) | buffer[*i + 3];
		TTL = (buffer[*i + 4] << 24) | (buffer[*i + 5] << 16) |
		    (buffer[*i + 6] << 8) | buffer[*i + 7];
		dataLength = (buffer[*i + 8] << 16) | buffer[*i + 9];

		*i += 10;

		if (*i + dataLength > length)
			@throw [OFTruncatedDataException exception];

		record = parseResourceRecord(name, DNSClass, recordType, TTL,
		    buffer, length, *i, dataLength);
		*i += dataLength;

		array = [ret objectForKey: name];

		if (array == nil) {
			array = [OFMutableArray array];
			[ret setObject: array forKey: name];
		}

		[array addObject: record];
	}

	objectEnumerator = [ret objectEnumerator];
	while ((array = [objectEnumerator nextObject]) != nil)
		[array makeImmutable];

	[ret makeImmutable];

	return ret;
}

@implementation OFDNSResolverContext
- (instancetype)initWithQuery: (OFDNSQuery *)query
			   ID: (OFNumber *)ID
		     settings: (OFDNSResolverSettings *)settings
		     delegate: (id <OFDNSResolverQueryDelegate>)delegate
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableData *queryData;
		uint16_t tmp;

		_query = [query copy];
		_ID = [ID retain];
		_settings = [settings copy];
		_delegate = [delegate retain];

		queryData = [OFMutableData dataWithCapacity: 512];

		/* Header */

		tmp = OF_BSWAP16_IF_LE(_ID.unsignedShortValue);
		[queryData addItems: &tmp count: 2];
		/* RD */
		tmp = OF_BSWAP16_IF_LE(1u << 8);
		[queryData addItems: &tmp count: 2];
		/* QDCOUNT */
		tmp = OF_BSWAP16_IF_LE(1);
		[queryData addItems: &tmp count: 2];
		/* ANCOUNT, NSCOUNT and ARCOUNT */
		[queryData increaseCountBy: 6];

		/* Question */

		/* QNAME */
		for (OFString *component in
		    [_query.domainName componentsSeparatedByString: @"."]) {
			size_t length = component.UTF8StringLength;
			uint8_t length8;

			if (length > 63 || queryData.count + length > 512)
				@throw [OFOutOfRangeException exception];

			length8 = (uint8_t)length;
			[queryData addItem: &length8];
			[queryData addItems: component.UTF8String
				      count: length];
		}

		/* QTYPE */
		tmp = OF_BSWAP16_IF_LE(_query.recordType);
		[queryData addItems: &tmp count: 2];
		/* QCLASS */
		tmp = OF_BSWAP16_IF_LE(_query.DNSClass);
		[queryData addItems: &tmp count: 2];
		[queryData makeImmutable];

		_queryData = [queryData copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_query release];
	[_ID release];
	[_settings release];
	[_delegate release];
	[_queryData release];
	[_TCPSocket release];
	[_TCPQueryData release];
	free(_TCPBuffer);
	[_cancelTimer release];

	[super dealloc];
}
@end

@implementation OFDNSResolver
#ifdef OF_AMIGAOS
+ (void)initialize
{
	if (self != [OFDNSResolver class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (instancetype)resolver
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_settings = [[OFDNSResolverSettings alloc] init];
		_queries = [[OFMutableDictionary alloc] init];
		_TCPQueries = [[OFMutableDictionary alloc] init];

		[_settings reload];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_settings release];
	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket release];
#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket release];
#endif
	[_queries release];
	[_TCPQueries release];

	[super dealloc];
}

- (OFDictionary *)staticHosts
{
	return _settings->_staticHosts;
}

- (void)setStaticHosts: (OFDictionary *)staticHosts
{
	OFDictionary *old = _settings->_staticHosts;
	_settings->_staticHosts = [staticHosts copy];
	[old release];
}

- (OFArray *)nameServers
{
	return _settings->_nameServers;
}

- (void)setNameServers: (OFArray *)nameServers
{
	OFArray *old = _settings->_nameServers;
	_settings->_nameServers = [nameServers copy];
	[old release];
}

- (OFString *)localDomain
{
	return _settings->_localDomain;
}

- (OFArray *)searchDomains
{
	return _settings->_searchDomains;
}

- (void)setSearchDomains: (OFArray *)searchDomains
{
	OFArray *old = _settings->_searchDomains;
	_settings->_searchDomains = [searchDomains copy];
	[old release];
}

- (of_time_interval_t)timeout
{
	return _settings->_timeout;
}

- (void)setTimeout: (of_time_interval_t)timeout
{
	_settings->_timeout = timeout;
}

- (unsigned int)maxAttempts
{
	return _settings->_maxAttempts;
}

- (void)setMaxAttempts: (unsigned int)maxAttempts
{
	_settings->_maxAttempts = maxAttempts;
}

- (unsigned int)minNumberOfDotsInAbsoluteName
{
	return _settings->_minNumberOfDotsInAbsoluteName;
}

- (void)setMinNumberOfDotsInAbsoluteName:
    (unsigned int)minNumberOfDotsInAbsoluteName
{
	_settings->_minNumberOfDotsInAbsoluteName =
	    minNumberOfDotsInAbsoluteName;
}

- (bool)usesTCP
{
	return _settings->_usesTCP;
}

- (void)setUsesTCP: (bool)usesTCP
{
	_settings->_usesTCP = usesTCP;
}

- (of_time_interval_t)configReloadInterval
{
	return _settings->_configReloadInterval;
}

- (void)setConfigReloadInterval: (of_time_interval_t)configReloadInterval
{
	_settings->_configReloadInterval = configReloadInterval;
}

- (void)of_sendQueryForContext: (OFDNSResolverContext *)context
		   runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFUDPSocket *sock;
	OFString *nameServer;

	[_queries setObject: context forKey: context->_ID];

	[context->_cancelTimer invalidate];
	[context->_cancelTimer release];
	context->_cancelTimer = nil;
	context->_cancelTimer = [[OFTimer alloc]
	    initWithFireDate: [OFDate dateWithTimeIntervalSinceNow:
				  context->_settings->_timeout]
		    interval: context->_settings->_timeout
		      target: self
		    selector: @selector(of_contextTimedOut:)
		      object: context
		     repeats: false];
	[[OFRunLoop currentRunLoop] addTimer: context->_cancelTimer
				     forMode: runLoopMode];

	nameServer = [context->_settings->_nameServers
	    objectAtIndex: context->_nameServersIndex];

	if (context->_settings->_usesTCP) {
		OF_ENSURE(context->_TCPSocket == nil);

		context->_TCPSocket = [[OFTCPSocket alloc] init];
		[_TCPQueries setObject: context forKey: context->_TCPSocket];

		context->_TCPSocket.delegate = self;
		[context->_TCPSocket asyncConnectToHost: nameServer
						   port: 53
					    runLoopMode: runLoopMode];
		return;
	}

	context->_usedNameServer = of_socket_address_parse_ip(nameServer, 53);

	switch (context->_usedNameServer.family) {
#ifdef OF_HAVE_IPV6
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		if (_IPv6Socket == nil) {
			of_socket_address_t address =
			    of_socket_address_parse_ip(@"::", 0);

			_IPv6Socket = [[OFUDPSocket alloc] init];
			[_IPv6Socket of_bindToAddress: &address
					    extraType: SOCK_DNS];
			_IPv6Socket.canBlock = false;
			_IPv6Socket.delegate = self;
		}

		sock = _IPv6Socket;
		break;
#endif
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
		if (_IPv4Socket == nil) {
			of_socket_address_t address =
			    of_socket_address_parse_ip(@"0.0.0.0", 0);

			_IPv4Socket = [[OFUDPSocket alloc] init];
			[_IPv4Socket of_bindToAddress: &address
					    extraType: SOCK_DNS];
			_IPv4Socket.canBlock = false;
			_IPv4Socket.delegate = self;
		}

		sock = _IPv4Socket;
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	[sock asyncSendData: context->_queryData
		   receiver: &context->_usedNameServer
		runLoopMode: runLoopMode];
	[sock asyncReceiveIntoBuffer: _buffer
			      length: BUFFER_LENGTH
			 runLoopMode: runLoopMode];
}

- (void)asyncPerformQuery: (OFDNSQuery *)query
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate
{
	[self asyncPerformQuery: query
		    runLoopMode: of_run_loop_mode_default
		       delegate: delegate];
}

- (void)asyncPerformQuery: (OFDNSQuery *)query
	      runLoopMode: (of_run_loop_mode_t)runLoopMode
		 delegate: (id <OFDNSResolverQueryDelegate>)delegate
{
	void *pool = objc_autoreleasePoolPush();
	OFNumber *ID;
	OFDNSResolverContext *context;

	/* Random, unused ID */
	do {
		ID = [OFNumber numberWithUnsignedShort: of_random16()];
	} while ([_queries objectForKey: ID] != nil);

	if (query.domainName.UTF8StringLength > 253)
		@throw [OFOutOfRangeException exception];

	if (_settings->_nameServers.count == 0) {
		id exception = [OFDNSQueryFailedException
		    exceptionWithQuery: query
				 error: OF_DNS_RESOLVER_ERROR_NO_NAME_SERVER];
		[delegate  resolver: self
		    didPerformQuery: query
			   response: nil
			  exception: exception];
		return;
	}

	context = [[[OFDNSResolverContext alloc]
	    initWithQuery: query
		       ID: ID
		 settings: _settings
		 delegate: delegate] autorelease];
	[self of_sendQueryForContext: context runLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

- (void)of_contextTimedOut: (OFDNSResolverContext *)context
{
	of_run_loop_mode_t runLoopMode = [OFRunLoop currentRunLoop].currentMode;
	OFDNSQueryFailedException *exception;

	if (context->_TCPSocket != nil) {
		context->_TCPSocket.delegate = nil;
		[context->_TCPSocket cancelAsyncRequests];

		[_TCPQueries removeObjectForKey: context->_TCPSocket];
		[context->_TCPSocket release];
		context->_TCPSocket = nil;
		context->_responseLength = 0;
	}

	if (context->_nameServersIndex + 1 <
	    context->_settings->_nameServers.count) {
		context->_nameServersIndex++;
		[self of_sendQueryForContext: context runLoopMode: runLoopMode];
		return;
	}

	if (++context->_attempt < context->_settings->_maxAttempts) {
		context->_nameServersIndex = 0;
		[self of_sendQueryForContext: context runLoopMode: runLoopMode];
		return;
	}

	context = [[context retain] autorelease];
	[_queries removeObjectForKey: context->_ID];

	/*
	 * Cancel any pending queries, to avoid a send being still pending and
	 * trying to access the query once it no longer exists.
	 */
	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket asyncReceiveIntoBuffer: _buffer length: BUFFER_LENGTH];
#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket asyncReceiveIntoBuffer: _buffer length: BUFFER_LENGTH];
#endif

	exception = [OFDNSQueryFailedException
	    exceptionWithQuery: context->_query
			 error: OF_DNS_RESOLVER_ERROR_TIMEOUT];

	[context->_delegate resolver: self
		     didPerformQuery: context->_query
			    response: nil
			   exception: exception];
}

- (bool)of_handleResponseBuffer: (unsigned char *)buffer
			 length: (size_t)length
			 sender: (const of_socket_address_t *)sender
{
	OFDictionary *answerRecords = nil, *authorityRecords = nil;
	OFDictionary *additionalRecords = nil;
	OFDNSResponse *response = nil;
	id exception = nil;
	OFNumber *ID;
	OFDNSResolverContext *context;

	if (length < 2)
		/* We can't get the ID to get the context. Ignore packet. */
		return true;

	ID = [OFNumber numberWithUnsignedShort: (buffer[0] << 8) | buffer[1]];
	context = [[[_queries objectForKey: ID] retain] autorelease];

	if (context == nil)
		return true;

	if (context->_TCPSocket != nil) {
		if ([_TCPQueries objectForKey: context->_TCPSocket] != context)
			return true;
	} else if (!of_socket_address_equal(sender, &context->_usedNameServer))
		return true;

	[context->_cancelTimer invalidate];
	[context->_cancelTimer release];
	context->_cancelTimer = nil;
	[_queries removeObjectForKey: ID];

	@try {
		of_dns_resolver_error_t error = 0;
		bool tryNextNameServer = false;
		const unsigned char *queryDataBuffer;
		size_t i;
		uint16_t numQuestions, numAnswers, numAuthorityRecords;
		uint16_t numAdditionalRecords;

		if (length < 12)
			@throw [OFTruncatedDataException exception];

		if (context->_queryData.itemSize != 1 ||
		    context->_queryData.count < 12)
			@throw [OFInvalidArgumentException exception];

		queryDataBuffer = context->_queryData.items;

		/* QR */
		if ((buffer[2] & 0x80) == 0)
			@throw [OFInvalidServerReplyException exception];

		/* Opcode */
		if ((buffer[2] & 0x78) != (queryDataBuffer[2] & 0x78))
			@throw [OFInvalidServerReplyException exception];

		/* TC */
		if (buffer[2] & 0x02) {
			of_run_loop_mode_t runLoopMode;

			if (context->_settings->_usesTCP)
				@throw [OFTruncatedDataException exception];

			context->_settings->_usesTCP = true;
			runLoopMode = [OFRunLoop currentRunLoop].currentMode;
			[self of_sendQueryForContext: context
					 runLoopMode: runLoopMode];
			return false;
		}

		/* RCODE */
		switch (buffer[3] & 0x0F) {
		case 0:
			break;
		case 1:
			error = OF_DNS_RESOLVER_ERROR_SERVER_INVALID_FORMAT;
			break;
		case 2:
			error = OF_DNS_RESOLVER_ERROR_SERVER_FAILURE;
			tryNextNameServer = true;
			break;
		case 3:
			error = OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR;
			break;
		case 4:
			error = OF_DNS_RESOLVER_ERROR_SERVER_NOT_IMPLEMENTED;
			tryNextNameServer = true;
			break;
		case 5:
			error = OF_DNS_RESOLVER_ERROR_SERVER_REFUSED;
			tryNextNameServer = true;
			break;
		default:
			error = OF_DNS_RESOLVER_ERROR_UNKNOWN;
			tryNextNameServer = true;
			break;
		}

		if (tryNextNameServer) {
			if (context->_nameServersIndex + 1 <
			    context->_settings->_nameServers.count) {
				of_run_loop_mode_t runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;

				context->_nameServersIndex++;

				[self of_sendQueryForContext: context
						 runLoopMode: runLoopMode];
				return false;
			}
		}

		if (buffer[3] & 0x0F)
			@throw [OFDNSQueryFailedException
			    exceptionWithQuery: context->_query
					 error: error];

		numQuestions = (buffer[4] << 8) | buffer[5];
		numAnswers = (buffer[6] << 8) | buffer[7];
		numAuthorityRecords = (buffer[8] << 8) | buffer[9];
		numAdditionalRecords = (buffer[10] << 8) | buffer[11];

		i = 12;

		/*
		 * Skip over the questions - we use the ID to identify the
		 * query.
		 *
		 * TODO: Compare to our query, just in case?
		 */
		for (uint_fast16_t j = 0; j < numQuestions; j++) {
			parseName(buffer, length, &i, MAX_ALLOWED_POINTERS);
			i += 4;
		}

		answerRecords = parseSection(buffer, length, &i, numAnswers);
		authorityRecords = parseSection(buffer, length, &i,
		    numAuthorityRecords);
		additionalRecords = parseSection(buffer, length, &i,
		    numAdditionalRecords);
		response = [OFDNSResponse
		    responseWithDomainName: context->_query.domainName
			     answerRecords: answerRecords
			  authorityRecords: authorityRecords
			 additionalRecords: additionalRecords];
	} @catch (id e) {
		exception = e;
	}

	if (exception != nil)
		response = nil;

	[context->_delegate resolver: self
		     didPerformQuery: context->_query
			    response: response
			   exception: exception];

	return false;
}

-	  (bool)socket: (OFDatagramSocket *)sock
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
		sender: (const of_socket_address_t *)sender
	     exception: (id)exception
{
	if (exception != nil)
		return true;

	return [self of_handleResponseBuffer: buffer
				      length: length
				      sender: sender];
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	OFDNSResolverContext *context = [_TCPQueries objectForKey: sock];

	OF_ENSURE(context != nil);

	if (exception != nil) {
		/*
		 * TODO: Handle error immediately instead of waiting for the
		 *	 timer to try the next nameserver or to retry.
		 */
		[_TCPQueries removeObjectForKey: context->_TCPSocket];
		[context->_TCPSocket release];
		context->_TCPSocket = nil;
		context->_responseLength = 0;
		return;
	}

	if (context->_TCPQueryData == nil) {
		size_t queryDataCount = context->_queryData.count;
		uint16_t tmp;

		if (queryDataCount > UINT16_MAX)
			@throw [OFOutOfRangeException exception];

		context->_TCPQueryData = [[OFMutableData alloc]
		    initWithCapacity: queryDataCount + 2];

		tmp = OF_BSWAP16_IF_LE(queryDataCount);
		[context->_TCPQueryData addItems: &tmp count: sizeof(tmp)];
		[context->_TCPQueryData addItems: context->_queryData.items
					   count: queryDataCount];
	}

	[sock asyncWriteData: context->_TCPQueryData];
}

- (OFData *)stream: (OFStream *)stream
      didWriteData: (OFData *)data
      bytesWritten: (size_t)bytesWritten
	 exception: (id)exception
{
	OFTCPSocket *sock = (OFTCPSocket *)stream;
	OFDNSResolverContext *context = [_TCPQueries objectForKey: sock];

	OF_ENSURE(context != nil);

	if (exception != nil) {
		/*
		 * TODO: Handle error immediately instead of waiting for the
		 *	 timer to try the next nameserver or to retry.
		 */
		[_TCPQueries removeObjectForKey: context->_TCPSocket];
		[context->_TCPSocket release];
		context->_TCPSocket = nil;
		context->_responseLength = 0;
		return nil;
	}

	if (context->_TCPBuffer == nil)
		context->_TCPBuffer = of_alloc(MAX_DNS_RESPONSE_LENGTH, 1);

	[sock asyncReadIntoBuffer: context->_TCPBuffer exactLength: 2];
	return nil;
}

-      (bool)stream: (OFStream *)stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	OFTCPSocket *sock = (OFTCPSocket *)stream;
	OFDNSResolverContext *context = [_TCPQueries objectForKey: sock];

	OF_ENSURE(context != nil);

	if (exception != nil) {
		/*
		 * TODO: Handle error immediately instead of waiting for the
		 *	 timer to try the next nameserver or to retry.
		 */
		goto done;
	}

	if (context->_responseLength == 0) {
		unsigned char *ucBuffer = buffer;

		OF_ENSURE(length == 2);

		context->_responseLength = (ucBuffer[0] << 8) | ucBuffer[1];

		if (context->_responseLength > MAX_DNS_RESPONSE_LENGTH)
			@throw [OFOutOfRangeException exception];

		if (context->_responseLength == 0)
			goto done;

		[sock asyncReadIntoBuffer: context->_TCPBuffer
			      exactLength: context->_responseLength];
		return false;
	}

	if (length != context->_responseLength)
		/*
		 * The connection was closed before we received the entire
		 * response.
		 */
		goto done;

	[self of_handleResponseBuffer: buffer length: length sender: NULL];

done:
	[_TCPQueries removeObjectForKey: context->_TCPSocket];
	[context->_TCPSocket release];
	context->_TCPSocket = nil;
	context->_responseLength = 0;

	return false;
}

- (void)asyncResolveAddressesForHost: (OFString *)host
			    delegate: (id <OFDNSResolverHostDelegate>)delegate
{
	[self asyncResolveAddressesForHost: host
			     addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY
			       runLoopMode: of_run_loop_mode_default
				  delegate: delegate];
}

- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (of_socket_address_family_t)addressFamily
			    delegate: (id <OFDNSResolverHostDelegate>)delegate
{
	[self asyncResolveAddressesForHost: host
			     addressFamily: addressFamily
			       runLoopMode: of_run_loop_mode_default
				  delegate: delegate];
}

- (void)asyncResolveAddressesForHost: (OFString *)host
		       addressFamily: (of_socket_address_family_t)addressFamily
			 runLoopMode: (of_run_loop_mode_t)runLoopMode
			    delegate: (id <OFDNSResolverHostDelegate>)delegate
{
	void *pool = objc_autoreleasePoolPush();
	OFHostAddressResolver *resolver = [[[OFHostAddressResolver alloc]
	    initWithHost: host
	   addressFamily: addressFamily
		resolver: self
		settings: _settings
	     runLoopMode: runLoopMode
		delegate: delegate] autorelease];

	[resolver asyncResolve];

	objc_autoreleasePoolPop(pool);
}

- (OFData *)resolveAddressesForHost: (OFString *)host
		      addressFamily: (of_socket_address_family_t)addressFamily
{
	void *pool = objc_autoreleasePoolPush();
	OFHostAddressResolver *resolver = [[[OFHostAddressResolver alloc]
	    initWithHost: host
	   addressFamily: addressFamily
		resolver: self
		settings: _settings
	     runLoopMode: nil
		delegate: nil] autorelease];
	OFData *addresses = [resolver resolve];

	[addresses retain];

	objc_autoreleasePoolPop(pool);

	return [addresses autorelease];
}

- (void)close
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator OF_GENERIC(OFDNSResolverContext *) *enumerator;
	OFDNSResolverContext *context;

	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket release];
	_IPv4Socket = nil;

#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket release];
	_IPv6Socket = nil;
#endif

	enumerator = [_queries objectEnumerator];
	while ((context = [enumerator nextObject]) != nil) {
		OFDNSQueryFailedException *exception;

		exception = [OFDNSQueryFailedException
		    exceptionWithQuery: context->_query
				 error: OF_DNS_RESOLVER_ERROR_CANCELED];

		[context->_delegate resolver: self
			     didPerformQuery: context->_query
				    response: nil
				   exception: exception];
	}

	[_queries removeAllObjects];

	objc_autoreleasePoolPop(pool);
}
@end
