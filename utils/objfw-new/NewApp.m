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

#include "config.h"

#include <errno.h>

#import "OFApplication.h"
#import "OFFile.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OFOpenItemFailedException.h"

void
newApp(OFString *name)
{
	OFString *path = [name stringByAppendingPathExtension: @"m"];
	OFFile *file = nil;
	@try {
		file = [OFFile fileWithPath: path mode: @"wx"];
	} @catch (OFOpenItemFailedException *e) {
		if (e.errNo != EEXIST)
			@throw e;

		[OFStdErr writeFormat: @"File %@ already exists! Aborting...\n",
				       e.path];
		[OFApplication terminateWithStatus: 1];
	}

	[file writeFormat: @"#import <ObjFW/ObjFW.h>\n"
			   @"\n"
			   @"@interface %@: OFObject <OFApplicationDelegate>\n"
			   @"@end\n"
			   @"\n"
			   @"OF_APPLICATION_DELEGATE(%@)\n"
			   @"\n"
			   @"@implementation %@\n"
			   @"- (void)applicationDidFinishLaunching\n"
			   @"{\n"
			   @"	[OFApplication terminate];\n"
			   @"}\n"
			   @"@end\n",
			   name, name, name];

	[file close];
}
