/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"

#import "common.h"

const OFChar16 OFKOI8UTable[] = {
	0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518, 0x251C, 0x2524,
	0x252C, 0x2534, 0x253C, 0x2580, 0x2584, 0x2588, 0x258C, 0x2590,
	0x2591, 0x2592, 0x2593, 0x2320, 0x25A0, 0x2219, 0x221A, 0x2248,
	0x2264,	0x2265, 0x00A0, 0x2321, 0x00B0, 0x00B2, 0x00B7, 0x00F7,
	0x2550, 0x2551, 0x2552, 0x0451, 0x0454, 0x2554, 0x0456, 0x0457,
	0x2557, 0x2558, 0x2559, 0x255A, 0x255B, 0x0491, 0x255D, 0x255E,
	0x255F, 0x2560, 0x2561, 0x0401, 0x0404, 0x2563, 0x0406, 0x0407,
	0x2566, 0x2567, 0x2568, 0x2569, 0x256A, 0x0490, 0x256C, 0x00A9,
	0x044E, 0x0430, 0x0431, 0x0446, 0x0434, 0x0435, 0x0444, 0x0433,
	0x0445, 0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E,
	0x043F, 0x044F, 0x0440, 0x0441, 0x0442, 0x0443, 0x0436, 0x0432,
	0x044C, 0x044B, 0x0437, 0x0448, 0x044D, 0x0449, 0x0447, 0x044A,
	0x042E, 0x0410, 0x0411, 0x0426, 0x0414, 0x0415, 0x0424, 0x0413,
	0x0425, 0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E,
	0x041F, 0x042F, 0x0420, 0x0421, 0x0422, 0x0423, 0x0416, 0x0412,
	0x042C, 0x042B, 0x0417, 0x0428, 0x042D, 0x0429, 0x0427, 0x042A
};
const size_t OFKOI8UTableOffset =
    256 - (sizeof(OFKOI8UTable) / sizeof(*OFKOI8UTable));

static const unsigned char page0[] = {
	0x9A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xBF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x9C, 0x00, 0x9D, 0x00, 0x00, 0x00, 0x00, 0x9E,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9F
};
static const uint8_t page0Start = 0xA0;

static const unsigned char page4[] = {
	0xB3, 0x00, 0x00, 0xB4, 0x00, 0xB6, 0xB7, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE1,
	0xE2, 0xF7, 0xE7, 0xE4, 0xE5, 0xF6, 0xFA, 0xE9,
	0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF2,
	0xF3, 0xF4, 0xF5, 0xE6, 0xE8, 0xE3, 0xFE, 0xFB,
	0xFD, 0xFF, 0xF9, 0xF8, 0xFC, 0xE0, 0xF1, 0xC1,
	0xC2, 0xD7, 0xC7, 0xC4, 0xC5, 0xD6, 0xDA, 0xC9,
	0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD2,
	0xD3, 0xD4, 0xD5, 0xC6, 0xC8, 0xC3, 0xDE, 0xDB,
	0xDD, 0xDF, 0xD9, 0xD8, 0xDC, 0xC0, 0xD1, 0x00,
	0xA3, 0x00, 0x00, 0xA4, 0x00, 0xA6, 0xA7, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBD,
	0xAD
};
static const uint8_t page4Start = 0x01;

static const unsigned char page22[] = {
	0x95, 0x96, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x97,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x98, 0x99
};
static const uint8_t page22Start = 0x19;

static const unsigned char page23[] = {
	0x93, 0x9B
};
static const uint8_t page23Start = 0x20;

static const unsigned char page25[] = {
	0x80, 0x00, 0x81, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x82, 0x00, 0x00, 0x00,
	0x83, 0x00, 0x00, 0x00, 0x84, 0x00, 0x00, 0x00,
	0x85, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x87, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x8A, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0xA0, 0xA1, 0xA2, 0x00, 0xA5, 0x00, 0xA7, 0xA8,
	0xA9, 0xAA, 0xAB, 0xAC, 0x00, 0xAE, 0xAF, 0xB0,
	0xB1, 0xB2, 0x00, 0xB5, 0x00, 0x00, 0xB8, 0xB9,
	0xBA, 0xBB, 0xBC, 0x00, 0xBE, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x8B, 0x00, 0x00, 0x00, 0x8C, 0x00, 0x00, 0x00,
	0x8D, 0x00, 0x00, 0x00, 0x8E, 0x00, 0x00, 0x00,
	0x8F, 0x90, 0x91, 0x92, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x94
};
static const uint8_t page25Start = 0x00;

bool
OFUnicodeToKOI8U(const OFUnichar *input, unsigned char *output, size_t length,
    bool lossy)
{
	for (size_t i = 0; i < length; i++) {
		OFUnichar c = input[i];

		if OF_UNLIKELY (c > 0x7F) {
			uint8_t idx;

			if OF_UNLIKELY (c > 0xFFFF) {
				if (lossy) {
					output[i] = '?';
					continue;
				} else
					return false;
			}

			switch (c >> 8) {
			CASE_MISSING_IS_ERROR(0)
			CASE_MISSING_IS_ERROR(4)
			CASE_MISSING_IS_ERROR(22)
			CASE_MISSING_IS_ERROR(23)
			CASE_MISSING_IS_ERROR(25)
			default:
				if (lossy) {
					output[i] = '?';
					continue;
				} else
					return false;
			}
		} else
			output[i] = (unsigned char)c;
	}

	return true;
}
