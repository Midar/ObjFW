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

#include <stdlib.h>

#import "TestsAppDelegate.h"

#ifdef OF_IOS
# include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef OF_PSP
# include <pspmoduleinfo.h>
# include <pspkernel.h>
# include <pspdebug.h>
# include <pspctrl.h>
PSP_MODULE_INFO("ObjFW Tests", 0, 0, 0);
#endif

#ifdef OF_WII
# define asm __asm__
# include <gccore.h>
# include <wiiuse/wpad.h>
# undef asm
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
#endif

#ifdef OF_PSP
static int
exit_cb(int arg1, int arg2, void *arg)
{
	sceKernelExitGame();

	return 0;
}

static int
callback_thread(SceSize args, void *argp)
{
	sceKernelRegisterExitCallback(
	    sceKernelCreateCallback("Exit Callback", exit_cb, NULL));
	sceKernelSleepThreadCB();

	return 0;
}
#endif

int
main(int argc, char *argv[])
{
#ifdef OF_PSP
	int tid;
#endif

#if defined(OF_OBJFW_RUNTIME) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS)
	/*
	 * This does not work on Win32 if ObjFW is built as a DLL.
	 *
	 * On AmigaOS, some destructors need to be able to send messages.
	 * Calling objc_exit() via atexit() would result in the runtime being
	 * destructed before for the destructors ran.
	 */
	atexit(objc_exit);
#endif

	/* We need deterministic hashes for tests */
	OFHashSeed = 0;

#ifdef OF_WII
	GXRModeObj *rmode;
	void *xfb;

	VIDEO_Init();
	WPAD_Init();

	rmode = VIDEO_GetPreferredMode(NULL);
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
	VIDEO_Configure(rmode);
	VIDEO_SetNextFramebuffer(xfb);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();

	VIDEO_WaitVSync();
	if (rmode->viTVMode & VI_NON_INTERLACE)
		VIDEO_WaitVSync();

	CON_InitEx(rmode, 10, 20, rmode->fbWidth - 10, rmode->xfbHeight - 20);
	VIDEO_ClearFrameBuffer(rmode, xfb, COLOR_BLACK);
#endif

#ifdef OF_PSP
	pspDebugScreenInit();

	sceCtrlSetSamplingCycle(0);
	sceCtrlSetSamplingMode(PSP_CTRL_MODE_DIGITAL);

	if ((tid = sceKernelCreateThread("update_thread", callback_thread,
	    0x11, 0xFA0, 0, 0)) >= 0)
		sceKernelStartThread(tid, 0, 0);
#endif

#ifdef OF_NINTENDO_DS
	consoleDemoInit();
#endif

#ifdef OF_NINTENDO_3DS
	gfxInitDefault();
	atexit(gfxExit);

	consoleInit(GFX_TOP, NULL);
#endif

#if defined(OF_WII) || defined(OF_PSP) || defined(OF_NINTENDO_DS) || \
	defined(OF_NINTENDO_3DS)
	@try {
		return OFApplicationMain(&argc, &argv,
		    [[TestsAppDelegate alloc] init]);
	} @catch (id e) {
		OFString *string = [OFString stringWithFormat:
		    @"\nRuntime error: Unhandled exception:\n%@\n", e];
		OFString *backtrace = [OFString stringWithFormat:
		    @"\nBacktrace:\n  %@\n\n",
		    [[e backtrace] componentsJoinedByString: @"\n  "]];

		[OFStdOut setForegroundColor: [OFColor red]];
		[OFStdOut writeString: string];
		[OFStdOut writeString: backtrace];

# if defined(OF_WII)
		[OFStdOut reset];
		[OFStdOut writeString: @"Press home button to exit!"];

		for (;;) {
			WPAD_ScanPads();

			if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME)
				[OFApplication terminateWithStatus: 1];

			VIDEO_WaitVSync();
		}
# elif defined(OF_PSP)
		sceKernelSleepThreadCB();
# elif defined(OF_NINTENDO_DS)
		[OFStdOut reset];
		[OFStdOut writeString: @"Press start button to exit!"];

		for (;;) {
			swiWaitForVBlank();
			scanKeys();
			if (keysDown() & KEY_START)
				[OFApplication terminateWithStatus: 1];
		}
# elif defined(OF_NINTENDO_3DS)
		[OFStdOut reset];
		[OFStdOut writeString: @"Press start button to exit!"];

		for (;;) {
			hidScanInput();

			if (hidKeysDown() & KEY_START)
				[OFApplication terminateWithStatus: 1];

			gspWaitForVBlank();
		}
# else
		abort();
# endif
	}
#else
	return OFApplicationMain(&argc, &argv, [[TestsAppDelegate alloc] init]);
#endif
}

@implementation TestsAppDelegate
- (void)outputTesting: (OFString *)test
	     inModule: (OFString *)module
{
	if (OFStdOut.hasTerminal) {
		[OFStdOut setForegroundColor: [OFColor yellow]];
		[OFStdOut writeFormat: @"[%@] %@: testing...", module, test];
	} else
		[OFStdOut writeFormat: @"[%@] %@: ", module, test];
}

- (void)outputSuccess: (OFString *)test
	     inModule: (OFString *)module
{
	if (OFStdOut.hasTerminal) {
		[OFStdOut setForegroundColor: [OFColor lime]];
		[OFStdOut eraseLine];
		[OFStdOut writeFormat: @"\r[%@] %@: ok\n", module, test];
	} else
		[OFStdOut writeLine: @"ok"];
}

- (void)outputFailure: (OFString *)test
	     inModule: (OFString *)module
{
	if (OFStdOut.hasTerminal) {
		[OFStdOut setForegroundColor: [OFColor red]];
		[OFStdOut eraseLine];
		[OFStdOut writeFormat: @"\r[%@] %@: failed\n", module, test];

#ifdef OF_WII
		[OFStdOut reset];
		[OFStdOut writeLine: @"Press A to continue!"];

		for (;;) {
			WPAD_ScanPads();

			if (WPAD_ButtonsDown(0) & WPAD_BUTTON_A)
				return;

			VIDEO_WaitVSync();
		}
#endif
#ifdef OF_PSP
		[OFStdOut reset];
		[OFStdOut writeLine: @"Press X to continue!"];

		for (;;) {
			SceCtrlData pad;

			sceCtrlReadBufferPositive(&pad, 1);
			if (pad.Buttons & PSP_CTRL_CROSS) {
				for (;;) {
					sceCtrlReadBufferPositive(&pad, 1);
					if (!(pad.Buttons & PSP_CTRL_CROSS))
						return;
				}
			}
		}
#endif
#ifdef OF_NINTENDO_DS
		[OFStdOut reset];
		[OFStdOut writeString: @"Press A to continue!"];

		for (;;) {
			swiWaitForVBlank();
			scanKeys();
			if (keysDown() & KEY_A)
				break;
		}
#endif
#ifdef OF_NINTENDO_3DS
		[OFStdOut reset];
		[OFStdOut writeString: @"Press A to continue!"];

		for (;;) {
			hidScanInput();

			if (hidKeysDown() & KEY_A)
				break;

			gspWaitForVBlank();
		}
#endif

		[OFStdOut writeString: @"\r"];
		[OFStdOut reset];
		[OFStdOut eraseLine];
	} else
		[OFStdOut writeLine: @"failed"];
}

- (void)applicationDidFinishLaunching
{
#if defined(OF_IOS) && defined(OF_HAVE_FILES)
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
	UInt8 resourcesPath[PATH_MAX];

	if (!CFURLGetFileSystemRepresentation(resourcesURL, true, resourcesPath,
	    PATH_MAX)) {
		[OFStdErr writeString: @"Failed to locate resources!\n"];
		[OFApplication terminateWithStatus: 1];
	}

	[[OFFileManager defaultManager] changeCurrentDirectoryPath:
	    [OFString stringWithUTF8String: (const char *)resourcesPath]];
#endif
#if defined(OF_WII) && defined(OF_HAVE_FILES)
	[[OFFileManager defaultManager]
	    changeCurrentDirectoryPath: @"/apps/objfw-tests"];
#endif

	[self runtimeTests];
#ifdef COMPILER_SUPPORTS_ARC
	[self runtimeARCTests];
#endif
	[self objectTests];
	[self methodSignatureTests];
	[self invocationTests];
	[self forwardingTests];
#ifdef OF_HAVE_BLOCKS
	[self blockTests];
#endif
	[self stringTests];
	[self characterSetTests];
	[self dataTests];
	[self arrayTests];
	[self dictionaryTests];
	[self listTests];
	[self setTests];
	[self dateTests];
	[self valueTests];
	[self numberTests];
	[self streamTests];
#ifdef OF_HAVE_FILES
	[self MD5HashTests];
	[self RIPEMD160HashTests];
	[self SHA1HashTests];
	[self SHA224HashTests];
	[self SHA256HashTests];
	[self SHA384HashTests];
	[self SHA512HashTests];
	[self HMACTests];
#endif
	[self PBKDF2Tests];
	[self scryptTests];
#if defined(OF_HAVE_FILES) && defined(HAVE_CODEPAGE_437)
	[self INIFileTests];
#endif
#ifdef OF_HAVE_SOCKETS
	[self socketTests];
	[self TCPSocketTests];
	[self UDPSocketTests];
# ifdef OF_HAVE_IPX
	[self IPXSocketTests];
	[self SPXSocketTests];
	[self SPXStreamSocketTests];
# endif
	[self kernelEventObserverTests];
#endif
#ifdef OF_HAVE_THREADS
	[self threadTests];
#endif
	[self URLTests];
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self HTTPClientTests];
#endif
#ifdef OF_HAVE_SOCKETS
	[self HTTPCookieTests];
	[self HTTPCookieManagerTests];
#endif
	[self XMLParserTests];
	[self XMLNodeTests];
	[self XMLElementBuilderTests];
#ifdef OF_HAVE_FILES
	[self serializationTests];
#endif
	[self JSONTests];
	[self propertyListTests];
#if defined(OF_HAVE_PLUGINS)
	[self pluginTests];
#endif
#ifdef OF_WINDOWS
	[self windowsRegistryKeyTests];
#endif

#ifdef OF_HAVE_SOCKETS
	[self DNSResolverTests];
#endif
	[self systemInfoTests];
	[self localeTests];

	[OFStdOut reset];

#if defined(OF_IOS)
	[OFStdOut writeFormat: @"%d tests failed!", _fails];
	[OFApplication terminateWithStatus: _fails];
#elif defined(OF_WII)
	[OFStdOut writeString: @"Press home button to exit!"];

	for (;;) {
		WPAD_ScanPads();

		if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME)
			[OFApplication terminateWithStatus: _fails];

		VIDEO_WaitVSync();
	}
#elif defined(OF_PSP)
	[OFStdOut writeFormat: @"%d tests failed!", _fails];

	sceKernelSleepThreadCB();
#elif defined(OF_NINTENDO_DS)
	[OFStdOut writeString: @"Press start button to exit!"];

	for (;;) {
		swiWaitForVBlank();
		scanKeys();
		if (keysDown() & KEY_START)
			[OFApplication terminateWithStatus: _fails];
	}
#elif defined(OF_NINTENDO_3DS)
	[OFStdOut writeString: @"Press start button to exit!"];

	for (;;) {
		hidScanInput();

		if (hidKeysDown() & KEY_START)
			[OFApplication terminateWithStatus: _fails];

		gspWaitForVBlank();
	}
#else
	[OFApplication terminateWithStatus: _fails];
#endif
}
@end
