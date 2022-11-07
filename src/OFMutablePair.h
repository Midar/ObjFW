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

#import "OFPair.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutablePair OFMutablePair.h ObjFW/OFMutablePair.h
 *
 * @brief A class for storing a pair of two objects.
 */
@interface OFMutablePair OF_GENERIC(FirstType, SecondType):
    OFPair OF_GENERIC(FirstType, SecondType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define FirstType id
# define SecondType id
#endif
{
	OF_RESERVE_IVARS(OFMutablePair, 4)
}

/**
 * @brief The first object of the pair.
 */
@property (readwrite, nonatomic, retain) FirstType firstObject;

/**
 * @brief The second object of the pair.
 */
@property (readwrite, nonatomic, retain) SecondType secondObject;

/**
 * @brief Converts the mutable pair to an immutable pair.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
#endif
@end

OF_ASSUME_NONNULL_END
