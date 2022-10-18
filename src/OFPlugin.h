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

#import "OFObject.h"

@class OFString;

#ifndef OF_WINDOWS
# include <dlfcn.h>
typedef void *OFPluginHandle;
#else
# include <windows.h>
typedef HMODULE OFPluginHandle;
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFPlugin OFPlugin.h ObjFW/OFPlugin.h
 *
 * @brief A class representing a loaded plugin (shared library).
 *
 */
OF_SUBCLASSING_RESTRICTED
@interface OFPlugin: OFObject
{
	OFPluginHandle _handle;
}

/**
 * @brief Returns the plugin path for a plugin with the specified name.
 *
 * E.g. on ELF systems, it appends .so, while on macOS and iOS, it creates the
 * appropriate plugin path. This can also be prefixed by a directory.
 *
 * @param name The name to return the plugin path for
 * @return The plugin path
 */
+ (OFString *)pathForName: (OFString *)name;

/**
 * @brief Creates a new OFPlugin by loading the plugin with the specified path.
 *
 * @param path The path to the plugin file. The suffix is appended
 *	       automatically.
 * @return An new, autoreleased OFPlugin
 * @throw OFLoadPluginFailedException The plugin could not be loaded
 */
+ (instancetype)pluginWithPath: (OFString *)path;

/**
 * @brief Initializes an already allocated OFPlugin by loading the plugin with
 *	  the specified path.
 *
 * @param path The path to the plugin file. The suffix is appended
 *	       automatically.
 * @return An initialized OFPlugin
 * @throw OFLoadPluginFailedException The plugin could not be loaded
 */
- (instancetype)initWithPath: (OFString *)path;

/**
 * @brief Returns the address for the specified symbol, or `nil` if not found.
 *
 * @param symbol The symbol to return the address for
 * @return The address for the speccified symbol, or `nil` if not found
 */
- (nullable void *)addressForSymbol: (OFString *)symbol;
@end

OF_ASSUME_NONNULL_END
