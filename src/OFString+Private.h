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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern char *_Nullable _OFStrDup(const char *_Nonnull) OF_VISIBILITY_HIDDEN;
extern size_t _OFUTF8StringEncode(OFUnichar, char *) OF_VISIBILITY_HIDDEN;
extern ssize_t _OFUTF8StringDecode(const char *, size_t, OFUnichar *)
    OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END