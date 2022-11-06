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

#import "OFXMLAttribute.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLAttribute
@synthesize name = _name, namespace = _namespace;

+ (instancetype)attributeWithName: (OFString *)name
			namespace: (OFString *)namespace
		      stringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithName: name
				 namespace: namespace
			       stringValue: stringValue] autorelease];
}

+ (instancetype)attributeWithName: (OFString *)name
		      stringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithName: name
			       stringValue: stringValue] autorelease];
}

- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue
{
	return [self initWithName: name
			namespace: nil
		      stringValue: stringValue];
}

- (instancetype)initWithName: (OFString *)name
		   namespace: (OFString *)namespace
		 stringValue: (OFString *)stringValue
{
	self = [super of_init];

	@try {
		_name = [name copy];
		_namespace = [namespace copy];
		_stringValue = [stringValue copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [super of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OFSerializationNS])
			@throw [OFInvalidArgumentException exception];

		_name = [[element attributeForName: @"name"].stringValue copy];
		_namespace = [[element attributeForName: @"namespace"]
		    .stringValue copy];
		_stringValue = [[element attributeForName: @"stringValue"]
		    .stringValue copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_namespace release];
	[_stringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return [[_stringValue copy] autorelease];
}

- (void)setStringValue: (OFString *)stringValue
{
	OFString *old = _stringValue;
	_stringValue = [stringValue copy];
	[old release];
}

- (bool)isEqual: (id)object
{
	OFXMLAttribute *attribute;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLAttribute class]])
		return false;

	attribute = object;

	if (![attribute->_name isEqual: _name])
		return false;
	if (attribute->_namespace != _namespace &&
	    ![attribute->_namespace isEqual: _namespace])
		return false;
	if (![attribute->_stringValue isEqual: _stringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddHash(&hash, _namespace.hash);
	OFHashAddHash(&hash, _stringValue.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OFSerializationNS];
	[element addAttributeWithName: @"name" stringValue: _name];

	if (_namespace != nil)
		[element addAttributeWithName: @"namespace"
				  stringValue: _namespace];

	[element addAttributeWithName: @"stringValue"
			  stringValue: _stringValue];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFXMLAttribute: name=%@, "
					   @"namespace=%@, stringValue=%@>",
					   _name, _namespace, _stringValue];
}
@end
