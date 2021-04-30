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

#define __NO_EXT_QNX

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#include "platform.h"

#if !defined(OF_WINDOWS) && !defined(OF_MORPHOS)
# include <signal.h>
#endif

#import "OFStream.h"
#import "OFStream+Private.h"
#import "OFASPrintF.h"
#import "OFData.h"
#import "OFKernelEventObserver.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#ifdef OF_HAVE_SOCKETS
# import "OFSocket+Private.h"
#endif
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFSetOptionFailedException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

#define minReadSize 512

@implementation OFStream
@synthesize buffersWrites = _buffersWrites;
@synthesize of_waitingForDelimiter = _waitingForDelimiter, delegate = _delegate;

#if defined(SIGPIPE) && defined(SIG_IGN)
+ (void)initialize
{
	if (self == [OFStream class])
		signal(SIGPIPE, SIG_IGN);
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
		if (self.class == [OFStream class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		_canBlock = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_readBufferMemory);
	OFFreeMemory(_writeBuffer);

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)copy
{
	return [self retain];
}

- (bool)isAtEndOfStream
{
	if (_readBufferLength > 0)
		return false;

	return [self lowlevelIsAtEndOfStream];
}

- (size_t)readIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_readBufferLength == 0) {
		/*
		 * For small sizes, it is cheaper to read more and cache the
		 * remainder - even if that means more copying of data - than
		 * to do a syscall for every read.
		 */
		if (length < minReadSize) {
			char tmp[minReadSize], *readBuffer;
			size_t bytesRead;

			bytesRead = [self lowlevelReadIntoBuffer: tmp
							  length: minReadSize];

			if (bytesRead > length) {
				memcpy(buffer, tmp, length);

				readBuffer = OFAllocMemory(bytesRead - length,
				    1);
				memcpy(readBuffer, tmp + length,
				    bytesRead - length);

				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bytesRead - length;

				return length;
			} else {
				memcpy(buffer, tmp, bytesRead);
				return bytesRead;
			}
		}

		return [self lowlevelReadIntoBuffer: buffer length: length];
	}

	if (length >= _readBufferLength) {
		size_t ret = _readBufferLength;
		memcpy(buffer, _readBuffer, _readBufferLength);

		OFFreeMemory(_readBufferMemory);
		_readBuffer = _readBufferMemory = NULL;
		_readBufferLength = 0;

		return ret;
	} else {
		memcpy(buffer, _readBuffer, length);

		_readBuffer += length;
		_readBufferLength -= length;

		return length;
	}
}

- (void)readIntoBuffer: (void *)buffer exactLength: (size_t)length
{
	size_t readLength = 0;

	while (readLength < length) {
		if (self.atEndOfStream)
			@throw [OFTruncatedDataException exception];

		readLength += [self readIntoBuffer: (char *)buffer + readLength
					    length: length - readLength];
	}
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadIntoBuffer: (void *)buffer length: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				      block: NULL
# endif
				   delegate: _delegate];
}

- (void)asyncReadIntoBuffer: (void *)buffer exactLength: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				      block: NULL
# endif
				   delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		      block: (OFStreamAsyncReadBlock)block
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: OFDefaultRunLoopMode
			    block: block];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
				      block: block
				   delegate: nil];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		      block: (OFStreamAsyncReadBlock)block
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: OFDefaultRunLoopMode
			    block: block];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
				      block: block
				   delegate: nil];
}
# endif
#endif

- (uint8_t)readInt8
{
	uint8_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 1];
	return ret;
}

- (uint16_t)readBigEndianInt16
{
	uint16_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 2];
	return OFFromBigEndian16(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromBigEndian32(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromBigEndian64(ret);
}

- (float)readBigEndianFloat
{
	float ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromBigEndianFloat(ret);
}

- (double)readBigEndianDouble
{
	double ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromBigEndianDouble(ret);
}

- (size_t)readBigEndianInt16sIntoBuffer: (uint16_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap16(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt32sIntoBuffer: (uint32_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap32(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt64sIntoBuffer: (uint64_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap64(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianFloatsIntoBuffer: (float *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

	[self readIntoBuffer: buffer exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwapFloat(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianDoublesIntoBuffer: (double *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

	[self readIntoBuffer: buffer exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwapDouble(buffer[i]);
#endif

	return size;
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 2];
	return OFFromLittleEndian16(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromLittleEndian32(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromLittleEndian64(ret);
}

- (float)readLittleEndianFloat
{
	float ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromLittleEndianFloat(ret);
}

- (double)readLittleEndianDouble
{
	double ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromLittleEndianDouble(ret);
}

- (size_t)readLittleEndianInt16sIntoBuffer: (uint16_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap16(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt32sIntoBuffer: (uint32_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap32(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt64sIntoBuffer: (uint64_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwap64(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianFloatsIntoBuffer: (float *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

	[self readIntoBuffer: buffer exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwapFloat(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianDoublesIntoBuffer: (double *)buffer
				      count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

	[self readIntoBuffer: buffer exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OFByteSwapDouble(buffer[i]);
#endif

	return size;
}

- (OFData *)readDataWithCount: (size_t)count
{
	return [self readDataWithItemSize: 1 count: count];
}

- (OFData *)readDataWithItemSize: (size_t)itemSize count: (size_t)count
{
	OFData *ret;
	char *buffer;

	if OF_UNLIKELY (count > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exception];

	buffer = OFAllocMemory(count, itemSize);
	@try {
		[self readIntoBuffer: buffer exactLength: count * itemSize];
		ret = [OFData dataWithItemsNoCopy: buffer
					    count: count
					 itemSize: itemSize
				     freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (OFData *)readDataUntilEndOfStream
{
	OFMutableData *data = [OFMutableData data];
	size_t pageSize = [OFSystemInfo pageSize];
	char *buffer = OFAllocMemory(1, pageSize);

	@try {
		while (!self.atEndOfStream) {
			size_t length =
			    [self readIntoBuffer: buffer length: pageSize];
			[data addItems: buffer count: length];
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	[data makeImmutable];
	return data;
}

- (OFString *)readStringWithLength: (size_t)length
{
	return [self readStringWithLength: length
				 encoding: OFStringEncodingUTF8];
}

- (OFString *)readStringWithLength: (size_t)length
			  encoding: (OFStringEncoding)encoding
{
	OFString *ret;
	char *buffer = OFAllocMemory(length + 1, 1);
	buffer[length] = 0;

	@try {
		[self readIntoBuffer: buffer exactLength: length];
		ret = [OFString stringWithCString: buffer encoding: encoding];
	} @finally {
		OFFreeMemory(buffer);
	}

	return ret;
}

- (OFString *)tryReadLineWithEncoding: (OFStringEncoding)encoding
{
	size_t pageSize, bufferLength;
	char *buffer, *readBuffer;
	OFString *ret;

	/* Look if there's a line or \0 in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if OF_UNLIKELY (_readBuffer[i] == '\n' ||
			    _readBuffer[i] == '\0') {
				size_t retLength = i;

				if (i > 0 && _readBuffer[i - 1] == '\r')
					retLength--;

				ret = [OFString stringWithCString: _readBuffer
							 encoding: encoding
							   length: retLength];

				_readBuffer += i + 1;
				_readBufferLength -= i + 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}
	}

	/* Read and see if we got a newline or \0 */
	pageSize = [OFSystemInfo pageSize];
	buffer = OFAllocMemory(1, pageSize);

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			size_t retLength;

			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			retLength = _readBufferLength;

			if (retLength > 0 && _readBuffer[retLength - 1] == '\r')
				retLength--;

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: retLength];

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a newline or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
			if OF_UNLIKELY (buffer[i] == '\n' ||
			    buffer[i] == '\0') {
				size_t retLength = _readBufferLength + i;
				char *retCString = OFAllocMemory(retLength, 1);

				if (_readBuffer != NULL)
					memcpy(retCString, _readBuffer,
					    _readBufferLength);
				memcpy(retCString + _readBufferLength,
				    buffer, i);

				if (retLength > 0 &&
				    retCString[retLength - 1] == '\r')
					retLength--;

				@try {
					ret = [OFString
					    stringWithCString: retCString
						     encoding: encoding
						       length: retLength];
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = OFAllocMemory(
						    _readBufferLength +
						    bufferLength, 1);

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						OFFreeMemory(_readBufferMemory);
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					OFFreeMemory(retCString);
				}

				readBuffer = OFAllocMemory(bufferLength - i - 1,
				    1);
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				OFFreeMemory(_readBufferMemory);
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* There was no newline or \0 */
		if (bufferLength > 0) {
			readBuffer = OFAllocMemory(
			    _readBufferLength + bufferLength, 1);

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	_waitingForDelimiter = true;
	return nil;
}

- (OFString *)readLine
{
	return [self readLineWithEncoding: OFStringEncodingUTF8];
}

- (OFString *)readLineWithEncoding: (OFStringEncoding)encoding
{
	OFString *line = nil;

	while ((line = [self tryReadLineWithEncoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return line;
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadLine
{
	[self asyncReadLineWithEncoding: OFStringEncodingUTF8
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					  block: NULL
# endif
				       delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadLineWithBlock: (OFStreamAsyncReadLineBlock)block
{
	[self asyncReadLineWithEncoding: OFStringEncodingUTF8
			    runLoopMode: OFDefaultRunLoopMode
				  block: block];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
			    block: (OFStreamAsyncReadLineBlock)block
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: OFDefaultRunLoopMode
				  block: block];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
			    block: (OFStreamAsyncReadLineBlock)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
					  block: block
				       delegate: nil];
}
# endif
#endif

- (OFString *)tryReadLine
{
	return [self tryReadLineWithEncoding: OFStringEncodingUTF8];
}

- (OFString *)tryReadTillDelimiter: (OFString *)delimiter
			  encoding: (OFStringEncoding)encoding
{
	const char *delimiterCString;
	size_t j, delimiterLength, pageSize, bufferLength;
	char *buffer, *readBuffer;
	OFString *ret;

	delimiterCString = [delimiter cStringWithEncoding: encoding];
	delimiterLength = [delimiter cStringLengthWithEncoding: encoding];
	j = 0;

	if (delimiterLength == 0)
		@throw [OFInvalidArgumentException exception];

	/* Look if there's something in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if (_readBuffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || _readBuffer[i] == '\0') {
				if (_readBuffer[i] == '\0')
					delimiterLength = 1;

				ret = [OFString
				    stringWithCString: _readBuffer
					     encoding: encoding
					      length: i + 1 - delimiterLength];

				_readBuffer += i + 1;
				_readBufferLength -= i + 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}
	}

	/* Read and see if we got a delimiter or \0 */
	pageSize = [OFSystemInfo pageSize];
	buffer = OFAllocMemory(1, pageSize);

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: _readBufferLength];

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a delimiter or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
			if (buffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || buffer[i] == '\0') {
				size_t retLength;
				char *retCString;

				if (buffer[i] == '\0')
					delimiterLength = 1;

				retLength = _readBufferLength + i + 1 -
				    delimiterLength;
				retCString = OFAllocMemory(retLength, 1);

				if (_readBuffer != NULL &&
				    _readBufferLength <= retLength)
					memcpy(retCString, _readBuffer,
					    _readBufferLength);
				else if (_readBuffer != NULL)
					memcpy(retCString, _readBuffer,
					    retLength);
				if (i >= delimiterLength)
					memcpy(retCString + _readBufferLength,
					    buffer, i + 1 - delimiterLength);

				@try {
					ret = [OFString
					    stringWithCString: retCString
						     encoding: encoding
						       length: retLength];
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = OFAllocMemory(
						    _readBufferLength +
						    bufferLength, 1);

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						OFFreeMemory(_readBufferMemory);
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					OFFreeMemory(retCString);
				}

				readBuffer = OFAllocMemory(bufferLength - i - 1,
				    1);
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				OFFreeMemory(_readBufferMemory);
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* Neither the delimiter nor \0 was found */
		if (bufferLength > 0) {
			readBuffer = OFAllocMemory(
			    _readBufferLength + bufferLength, 1);

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	_waitingForDelimiter = true;
	return nil;
}


- (OFString *)readTillDelimiter: (OFString *)delimiter
{
	return [self readTillDelimiter: delimiter
			      encoding: OFStringEncodingUTF8];
}

- (OFString *)readTillDelimiter: (OFString *)delimiter
		       encoding: (OFStringEncoding)encoding
{
	OFString *ret = nil;

	while ((ret = [self tryReadTillDelimiter: delimiter
					encoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return ret;
}

- (OFString *)tryReadTillDelimiter: (OFString *)delimiter
{
	return [self tryReadTillDelimiter: delimiter
				 encoding: OFStringEncodingUTF8];
}

- (void)flushWriteBuffer
{
	if (_writeBuffer == NULL)
		return;

	[self lowlevelWriteBuffer: _writeBuffer length: _writeBufferLength];

	OFFreeMemory(_writeBuffer);
	_writeBuffer = NULL;
	_writeBufferLength = 0;
}

- (size_t)writeBuffer: (const void *)buffer
	       length: (size_t)length
{
	if (!_buffersWrites) {
		size_t bytesWritten = [self lowlevelWriteBuffer: buffer
							 length: length];

		if (_canBlock && bytesWritten < length)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: bytesWritten
					  errNo: 0];

		return bytesWritten;
	} else {
		_writeBuffer = OFResizeMemory(_writeBuffer,
		    _writeBufferLength + length, 1);
		memcpy(_writeBuffer + _writeBufferLength, buffer, length);
		_writeBufferLength += length;

		return length;
	}
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncWriteData: (OFData *)data
{
	[self asyncWriteData: data runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteData: (OFData *)data runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				       block: NULL
# endif
				    delegate: _delegate];
}

- (void)asyncWriteString: (OFString *)string
{
	[self asyncWriteString: string
		      encoding: OFStringEncodingUTF8
		   runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				       block: NULL
# endif
				    delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncWriteData: (OFData *)data block: (OFStreamAsyncWriteDataBlock)block
{
	[self asyncWriteData: data
		 runLoopMode: OFDefaultRunLoopMode
		       block: block];
}

- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (OFRunLoopMode)runLoopMode
		 block: (OFStreamAsyncWriteDataBlock)block
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
				       block: block
				    delegate: nil];
}

- (void)asyncWriteString: (OFString *)string
		   block: (OFStreamAsyncWriteStringBlock)block
{
	[self asyncWriteString: string
		      encoding: OFStringEncodingUTF8
		   runLoopMode: OFDefaultRunLoopMode
			 block: block];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
		   block: (OFStreamAsyncWriteStringBlock)block
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: OFDefaultRunLoopMode
			 block: block];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
		   block: (OFStreamAsyncWriteStringBlock)block
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
				       block: block
				    delegate: nil];
}
# endif
#endif

- (void)writeInt8: (uint8_t)int8
{
	[self writeBuffer: (char *)&int8 length: 1];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = OFToBigEndian16(int16);
	[self writeBuffer: (char *)&int16 length: 2];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = OFToBigEndian32(int32);
	[self writeBuffer: (char *)&int32 length: 4];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = OFToBigEndian64(int64);
	[self writeBuffer: (char *)&int64 length: 8];
}

- (void)writeBigEndianFloat: (float)float_
{
	float_ = OFToBigEndianFloat(float_);
	[self writeBuffer: (char *)&float_ length: 4];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = OFToBigEndianDouble(double_);
	[self writeBuffer: (char *)&double_ length: 8];
}

- (size_t)writeBigEndianInt16s: (const uint16_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint16_t *tmp = OFAllocMemory(count, sizeof(uint16_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap16(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt32s: (const uint32_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint32_t *tmp = OFAllocMemory(count, sizeof(uint32_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap32(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt64s: (const uint64_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint64_t *tmp = OFAllocMemory(count, sizeof(uint64_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap64(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeBigEndianFloats: (const float *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	float *tmp = OFAllocMemory(count, sizeof(float));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwapFloat(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeBigEndianDoubles: (const double *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	double *tmp = OFAllocMemory(count, sizeof(double));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwapDouble(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (void)writeLittleEndianInt16: (uint16_t)int16
{
	int16 = OFToLittleEndian16(int16);
	[self writeBuffer: (char *)&int16 length: 2];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = OFToLittleEndian32(int32);
	[self writeBuffer: (char *)&int32 length: 4];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = OFToLittleEndian64(int64);
	[self writeBuffer: (char *)&int64 length: 8];
}

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = OFToLittleEndianFloat(float_);
	[self writeBuffer: (char *)&float_ length: 4];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = OFToLittleEndianDouble(double_);
	[self writeBuffer: (char *)&double_ length: 8];
}

- (size_t)writeLittleEndianInt16s: (const uint16_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint16_t *tmp = OFAllocMemory(count, sizeof(uint16_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap16(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt32s: (const uint32_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint32_t *tmp = OFAllocMemory(count, sizeof(uint32_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap32(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt64s: (const uint64_t *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	uint64_t *tmp = OFAllocMemory(count, sizeof(uint64_t));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwap64(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeLittleEndianFloats: (const float *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	float *tmp = OFAllocMemory(count, sizeof(float));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwapFloat(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeLittleEndianDoubles: (const double *)buffer count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer length: size];
#else
	double *tmp = OFAllocMemory(count, sizeof(double));

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OFByteSwapDouble(buffer[i]);

		[self writeBuffer: tmp length: size];
	} @finally {
		OFFreeMemory(tmp);
	}
#endif

	return size;
}

- (size_t)writeData: (OFData *)data
{
	void *pool;
	size_t length;

	if (data == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	length = data.count * data.itemSize;
	[self writeBuffer: data.items length: length];

	objc_autoreleasePoolPop(pool);

	return length;
}

- (size_t)writeString: (OFString *)string
{
	return [self writeString: string encoding: OFStringEncodingUTF8];
}

- (size_t)writeString: (OFString *)string encoding: (OFStringEncoding)encoding
{
	void *pool;
	size_t length;

	if (string == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	length = [string cStringLengthWithEncoding: encoding];

	[self writeBuffer: [string cStringWithEncoding: encoding]
		   length: length];

	objc_autoreleasePoolPop(pool);

	return length;
}

- (size_t)writeLine: (OFString *)string
{
	return [self writeLine: string encoding: OFStringEncodingUTF8];
}

- (size_t)writeLine: (OFString *)string encoding: (OFStringEncoding)encoding
{
	size_t stringLength = [string cStringLengthWithEncoding: encoding];
	char *buffer;

	buffer = OFAllocMemory(stringLength + 1, 1);

	@try {
		memcpy(buffer, [string cStringWithEncoding: encoding],
		    stringLength);
		buffer[stringLength] = '\n';

		[self writeBuffer: buffer length: stringLength + 1];
	} @finally {
		OFFreeMemory(buffer);
	}

	return stringLength + 1;
}

- (size_t)writeFormat: (OFConstantString *)format, ...
{
	va_list arguments;
	size_t ret;

	va_start(arguments, format);
	ret = [self writeFormat: format arguments: arguments];
	va_end(arguments);

	return ret;
}

- (size_t)writeFormat: (OFConstantString *)format arguments: (va_list)arguments
{
	char *UTF8String;
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((length = OFVASPrintF(&UTF8String, format.UTF8String,
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		[self writeBuffer: UTF8String length: length];
	} @finally {
		free(UTF8String);
	}

	return length;
}

- (bool)hasDataInReadBuffer
{
	return (_readBufferLength > 0);
}

- (bool)canBlock
{
	return _canBlock;
}

- (void)setCanBlock: (bool)canBlock
{
#if defined(HAVE_FCNTL) && !defined(OF_AMIGAOS)
	bool readImplemented = false, writeImplemented = false;

	@try {
		int readFlags;

		readFlags = fcntl(((id <OFReadyForReadingObserving>)self)
		    .fileDescriptorForReading, F_GETFL, 0);

		readImplemented = true;

		if (readFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];

		if (canBlock)
			readFlags &= ~O_NONBLOCK;
		else
			readFlags |= O_NONBLOCK;

		if (fcntl(((id <OFReadyForReadingObserving>)self)
		    .fileDescriptorForReading, F_SETFL, readFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];
	} @catch (OFNotImplementedException *e) {
	}

	@try {
		int writeFlags;

		writeFlags = fcntl(((id <OFReadyForWritingObserving>)self)
		    .fileDescriptorForWriting, F_GETFL, 0);

		writeImplemented = true;

		if (writeFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];

		if (canBlock)
			writeFlags &= ~O_NONBLOCK;
		else
			writeFlags |= O_NONBLOCK;

		if (fcntl(((id <OFReadyForWritingObserving>)self)
		    .fileDescriptorForWriting, F_SETFL, writeFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];
	} @catch (OFNotImplementedException *e) {
	}

	if (!readImplemented && !writeImplemented)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	_canBlock = canBlock;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (int)fileDescriptorForReading
{
	OF_UNRECOGNIZED_SELECTOR
}

- (int)fileDescriptorForWriting
{
	OF_UNRECOGNIZED_SELECTOR
}

#ifdef OF_HAVE_SOCKETS
- (void)cancelAsyncRequests
{
	[OFRunLoop of_cancelAsyncRequestsForObject: self
					      mode: OFDefaultRunLoopMode];
}
#endif

- (void)unreadFromBuffer: (const void *)buffer length: (size_t)length
{
	char *readBuffer;

	if (length > SIZE_MAX - _readBufferLength)
		@throw [OFOutOfRangeException exception];

	readBuffer = OFAllocMemory(_readBufferLength + length, 1);
	memcpy(readBuffer, buffer, length);
	memcpy(readBuffer + length, _readBuffer, _readBufferLength);

	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = readBuffer;
	_readBufferLength += length;
}

- (void)close
{
	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = NULL;
	_readBufferLength = 0;

	OFFreeMemory(_writeBuffer);
	_writeBuffer = NULL;
	_writeBufferLength = 0;
	_buffersWrites = false;

	_waitingForDelimiter = false;
}
@end
