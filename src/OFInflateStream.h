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

#import "OFStream.h"
#import "OFKernelEventObserver.h"

OF_ASSUME_NONNULL_BEGIN

#define OFInflateStreamBufferSize 4096

/**
 * @class OFInflateStream OFInflateStream.h ObjFW/OFInflateStream.h
 *
 * @note This class only conforms to OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @brief A class that handles Deflate decompression transparently for an
 *	  underlying stream.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFInflateStream: OFStream <OFReadyForReadingObserving>
{
	OFStream *_stream;
	unsigned char _buffer[OFInflateStreamBufferSize];
	uint16_t _bufferIndex, _bufferLength;
	uint8_t _byte;
	uint8_t _bitIndex, _savedBitsLength;
	uint16_t _savedBits;
	unsigned char *_Nullable _slidingWindow;
	uint16_t _slidingWindowIndex, _slidingWindowMask;
	int _state;
	union {
		struct {
			uint8_t position;
			uint8_t length[4];
		} uncompressedHeader;
		struct {
			uint16_t position, length;
		} uncompressed;
		struct {
			struct _OFHuffmanTree *_Nullable litLenTree;
			struct _OFHuffmanTree *_Nullable distTree;
			struct _OFHuffmanTree *_Nullable codeLenTree;
			struct _OFHuffmanTree *_Nullable treeIter;
			uint8_t *_Nullable lengths;
			uint16_t receivedCount;
			uint8_t value, litLenCodesCount, distCodesCount;
			uint8_t codeLenCodesCount;
		} huffmanTree;
		struct {
			struct _OFHuffmanTree *_Nullable litLenTree;
			struct _OFHuffmanTree *_Nullable distTree;
			struct _OFHuffmanTree *_Nullable treeIter;
			int state;
			uint16_t value, length, distance, extraBits;
		} huffman;
	} _context;
	bool _inLastBlock, _atEndOfStream;
}

/**
 * @brief Creates a new OFInflateStream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFInflateStream
 */
+ (instancetype)streamWithStream: (OFStream *)stream;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFInflateStream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFInflateStream
 */
- (instancetype)initWithStream: (OFStream *)stream OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
