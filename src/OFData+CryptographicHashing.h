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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_CryptographicHashing_reference;
#ifdef __cplusplus
}
#endif

@interface OFData (CryptographicHashing)
/**
 * @brief The MD5 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringByMD5Hashing;

/**
 * @brief The RIPEMD-160 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringByRIPEMD160Hashing;

/**
 * @brief The SHA-1 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA1Hashing;

/**
 * @brief The SHA-224 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA224Hashing;

/**
 * @brief The SHA-256 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA256Hashing;

/**
 * @brief The SHA-384 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA384Hashing;

/**
 * @brief The SHA-512 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA512Hashing;
@end

OF_ASSUME_NONNULL_END
