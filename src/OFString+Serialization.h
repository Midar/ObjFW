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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_Serialization_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (Serialization)
/**
 * @brief The string interpreted as serialization and parsed as an object.
 *
 * @throw OFMalformedXMLException The XML was malformed
 * @throw OFUnboundNamespaceException A prefix was used that was not bound to
 *				      any namespace
 * @throw OFInvalidEncodingException The XML is not in the encoding it specified
 * @throw OFUnsupportedVersionException The serialization is in an unsupported
 *					version
 */
@property (readonly, nonatomic) id objectByDeserializing;
@end

OF_ASSUME_NONNULL_END
