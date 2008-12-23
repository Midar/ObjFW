/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

#define MD5_DIGEST_SIZE	 16
#define SHA1_DIGEST_SIZE 20

/**
 * The OFMD5Hash class provides functions to create an MD5 hash.
 */
@interface OFMD5Hash: OFObject
{
	uint32_t buf[4];
	uint32_t bits[2];
	uint8_t	 in[64];

	BOOL	 calculated;
}

- init;

/**
 * Adds a buffer to the hash to be calculated.
 *
 * \param buf The buffer which should be included into calculation.
 * \param size The size of the buffer
 */
- updateWithBuffer: (const uint8_t*)buf
	    ofSize: (size_t)size;

/**
 * \return A buffer containing the hash (MD5_DIGEST_SIZE = 16 bytes).
 *	   The buffer is part of object's memory pool.
 */
- (uint8_t*)digest;
@end

/**
 * The OFSHA1Hash class provides functions to create an SHA1 hash.
 */
@interface OFSHA1Hash: OFObject
{
	uint32_t    state[5];
	uint64_t    count;
	uint8_t	    buffer[64];
	uint8_t	    digest[SHA1_DIGEST_SIZE];

	BOOL	 calculated;
}

- init;

/**
 * Adds a buffer to the hash to be calculated.
 *
 * \param buf The buffer which should be included into calculation.
 * \param size The size of the buffer
 */
- updateWithBuffer: (const uint8_t*)buf
	    ofSize: (size_t)size;

/**
 * \return A buffer containing the hash (SHA1_DIGEST_SIZE = 20 bytes).
 *	   The buffer is part of object's memory pool.
 */
- (uint8_t*)digest;
@end
