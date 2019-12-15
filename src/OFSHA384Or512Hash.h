/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFCryptoHash.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSecureData;

/*!
 * @class OFSHA384Or512Hash OFSHA384Or512Hash.h ObjFW/OFSHA384Or512Hash.h
 *
 * @brief A base class for SHA-384 and SHA-512.
 */
@interface OFSHA384Or512Hash: OFObject <OFCryptoHash>
{
@private
	OFSecureData *_iVarsData;
@protected
	struct of_sha384_or_512_hash_ivars {
		uint64_t state[8];
		uint64_t bits[2];
		union of_sha384_or_512_hash_buffer {
			uint8_t bytes[128];
			uint64_t words[80];
		} buffer;
		size_t bufferLength;
	} *_iVars;
@private
	bool _calculated;
	OF_RESERVE_IVARS(4)
}
@end

OF_ASSUME_NONNULL_END
