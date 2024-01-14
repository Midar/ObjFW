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

#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFAAAADNSResourceRecord \
 *	  OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class represenging a DNS resource record.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFAAAADNSResourceRecord: OFDNSResourceRecord
{
	OFSocketAddress _address;
}

/**
 * @brief The IPv6 address of the resource record.
 */
@property (readonly, nonatomic) const OFSocketAddress *address;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFAAAADNSResourceRecord with the
 *	  specified name, class, address and time to live.
 *
 * @param name The name for the resource record
 * @param address The address for the resource record
 * @param TTL The time to live for the resource record
 * @return An initialized OFAAAADNSResourceRecord
 */
- (instancetype)initWithName: (OFString *)name
		     address: (const OFSocketAddress *)address
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
