/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#include <stdbool.h>

#import "OFOnce.h"
#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_ATOMIC_OPS)
# import "OFAtomic.h"
# import "OFPlainMutex.h"
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# undef Class
#endif

void
OFOnce(OFOnceControl *control, void (*function)(void))
{
#if !defined(OF_HAVE_THREADS)
	if (*control == 0) {
		function();
		*control = 1;
	}
#elif defined(OF_HAVE_PTHREADS)
	pthread_once(control, function);
#elif defined(OF_HAVE_ATOMIC_OPS)
	/* Avoid atomic operations in case it's already done. */
	if (*control == 2)
		return;

	if (OFAtomicIntCompareAndSwap(control, 0, 1)) {
		function();

		OFMemoryBarrier();

		OFAtomicIntIncrease(control);
	} else
		while (*control == 1)
			OFYieldThread();
#elif defined(OF_AMIGAOS)
	bool run = false;

	/* Avoid Forbid() in case it's already done. */
	if (*control == 2)
		return;

	Forbid();

	switch (*control) {
	case 0:
		*control = 1;
		run = true;
		break;
	case 1:
		while (*control == 1) {
			Permit();
			Forbid();
		}
	}

	Permit();

	if (run) {
		function();
		*control = 2;
	}
#else
# error No OFOnce available
#endif
}
