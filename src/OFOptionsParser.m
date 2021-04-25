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

#import "OFOptionsParser.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFMapTable.h"

#import "OFInvalidArgumentException.h"

static unsigned long
stringHash(void *object)
{
	return ((OFString *)object).hash;
}

static bool
stringEqual(void *object1, void *object2)
{
	return [(OFString *)object1 isEqual: (OFString *)object2];
}

@implementation OFOptionsParser
@synthesize lastOption = _lastOption, lastLongOption = _lastLongOption;
@synthesize argument = _argument;

+ (instancetype)parserWithOptions: (const OFOptionsParserOption *)options
{
	return [[[self alloc] initWithOptions: options] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithOptions: (const OFOptionsParserOption *)options
{
	self = [super init];

	@try {
		size_t count = 0;
		const OFOptionsParserOption *iter;
		OFOptionsParserOption *iter2;
		const OFMapTableFunctions keyFunctions = {
			.hash = stringHash,
			.equal = stringEqual
		};
		const OFMapTableFunctions objectFunctions = { NULL };

		/* Count, sanity check, initialize pointers */
		for (iter = options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++) {
			if (iter->hasArgument < -1 || iter->hasArgument > 1)
				@throw [OFInvalidArgumentException exception];

			if (iter->shortOption != '\0' &&
			    iter->hasArgument == -1)
				@throw [OFInvalidArgumentException exception];

			if (iter->hasArgument == 0 && iter->argumentPtr != NULL)
				@throw [OFInvalidArgumentException exception];

			if (iter->isSpecifiedPtr)
				*iter->isSpecifiedPtr = false;
			if (iter->argumentPtr)
				*iter->argumentPtr = nil;

			count++;
		}

		_options = OFAllocMemory(count + 1, sizeof(*_options));
		_longOptions = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions];

		for (iter = options, iter2 = _options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++, iter2++) {
			iter2->shortOption = iter->shortOption;
			iter2->longOption = nil;
			iter2->hasArgument = iter->hasArgument;
			iter2->isSpecifiedPtr = iter->isSpecifiedPtr;
			iter2->argumentPtr = iter->argumentPtr;

			if (iter->longOption != nil) {
				@try {
					iter2->longOption =
					    [iter->longOption copy];

					if ([_longOptions objectForKey:
					    iter2->longOption] != NULL)
						@throw
						    [OFInvalidArgumentException
						    exception];

					[_longOptions
					    setObject: iter2
					       forKey: iter2->longOption];
				} @catch (id e) {
					/*
					 * Make sure we are in a consistent
					 * state where dealloc works.
					 */
					[iter2->longOption release];

					iter2->shortOption = '\0';
					iter2->longOption = nil;

					@throw e;
				}
			}
		}
		iter2->shortOption = '\0';
		iter2->longOption = nil;

		_arguments = [[OFApplication arguments] retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_options != NULL)
		for (OFOptionsParserOption *iter = _options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++)
			[iter->longOption release];

	OFFreeMemory(_options);
	[_longOptions release];

	[_arguments release];
	[_argument release];

	[super dealloc];
}

- (OFUnichar)nextOption
{
	OFOptionsParserOption *iter;
	OFString *argument;

	if (_done || _index >= _arguments.count)
		return '\0';

	[_lastLongOption release];
	[_argument release];
	_lastLongOption = nil;
	_argument = nil;

	argument = [_arguments objectAtIndex: _index];

	if (_subIndex == 0) {
		if (argument.length < 2 ||
		    [argument characterAtIndex: 0] != '-') {
			_done = true;
			return '\0';
		}

		if ([argument isEqual: @"--"]) {
			_done = true;
			_index++;
			return '\0';
		}

		if ([argument hasPrefix: @"--"]) {
			void *pool = objc_autoreleasePoolPush();
			size_t pos;
			OFOptionsParserOption *option;

			_lastOption = '-';
			_index++;

			if ((pos = [argument rangeOfString: @"="].location) !=
			    OFNotFound)
				_argument = [[argument
				    substringFromIndex: pos + 1] copy];
			else
				pos = argument.length;

			_lastLongOption = [[argument substringWithRange:
			    OFRangeMake(2, pos - 2)] copy];

			objc_autoreleasePoolPop(pool);

			option = [_longOptions objectForKey: _lastLongOption];
			if (option == NULL)
				return '?';

			if (option->hasArgument == 1 && _argument == nil)
				return ':';
			if (option->hasArgument == 0 && _argument != nil)
				return '=';

			if (option->isSpecifiedPtr != NULL)
				*option->isSpecifiedPtr = true;
			if (option->argumentPtr != NULL)
				*option->argumentPtr =
				    [[_argument copy] autorelease];

			if (option->shortOption != '\0')
				_lastOption = option->shortOption;

			return _lastOption;
		}

		_subIndex = 1;
	}

	_lastOption = [argument characterAtIndex: _subIndex++];

	if (_subIndex >= argument.length) {
		_index++;
		_subIndex = 0;
	}

	for (iter = _options;
	    iter->shortOption != '\0' || iter->longOption != nil; iter++) {
		if (iter->shortOption == _lastOption) {
			if (iter->hasArgument == 0) {
				if (iter->isSpecifiedPtr != NULL)
					*iter->isSpecifiedPtr = true;

				return _lastOption;
			}

			if (_index >= _arguments.count)
				return ':';

			argument = [_arguments objectAtIndex: _index];
			argument = [argument substringFromIndex: _subIndex];

			_argument = [argument copy];

			if (iter->isSpecifiedPtr != NULL)
				*iter->isSpecifiedPtr = true;
			if (iter->argumentPtr != NULL)
				*iter->argumentPtr =
				    [[_argument copy] autorelease];

			_index++;
			_subIndex = 0;

			return _lastOption;
		}
	}

	return '?';
}

- (OFArray *)remainingArguments
{
	return [_arguments objectsInRange:
	    OFRangeMake(_index, _arguments.count - _index)];
}
@end
