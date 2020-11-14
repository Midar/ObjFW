/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFLocale.h"
#import "OFOptionsParser.h"
#ifdef OF_HAVE_PLUGINS
# import "OFPlugin.h"
#endif
#import "OFSandbox.h"
#import "OFStdIOStream.h"
#import "OFSystemInfo.h"
#import "OFTCPSocket.h"
#import "OFTLSSocket.h"
#import "OFURL.h"

#import "OFConnectionFailedException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFResolveHostFailedException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

#import "ProgressBar.h"

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

@interface OFHTTP: OFObject <OFApplicationDelegate, OFHTTPClientDelegate,
    OFStreamDelegate>
{
	OFArray OF_GENERIC(OFString *) *_URLs;
	size_t _URLIndex;
	int _errorCode;
	OFString *_outputPath, *_currentFileName;
	bool _continue, _force, _detectFileName, _detectFileNameRequest;
	bool _detectedFileName, _quiet, _verbose, _insecure, _ignoreStatus;
	OFStream *_body;
	of_http_request_method_t _method;
	OFMutableDictionary *_clientHeaders;
	OFHTTPClient *_HTTPClient;
	char *_buffer;
	OFStream *_output;
	unsigned long long _received, _length, _resumedFrom;
	ProgressBar *_progressBar;
}

- (void)downloadNextURL;
@end

OF_APPLICATION_DELEGATE(OFHTTP)

static void
help(OFStream *stream, bool full, int status)
{
	[of_stderr writeLine:
	    OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] -[cehHmoOPqv] url1 [url2 ...]",
	    @"prog", [OFApplication programName])];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine: OF_LOCALIZED(@"full_usage",
		    @"Options:\n    "
		    @"-b  --body           "
		    @"  Specify the file to send as body\n    "
		    @"                     "
		    @"  (- for standard input)\n    "
		    @"-c  --continue       "
		    @"  Continue download of existing file\n    "
		    @"-f  --force          "
		    @"  Force / overwrite existing file\n    "
		    @"-h  --help           "
		    @"  Show this help\n    "
		    @"-H  --header         "
		    @"  Add a header (e.g. X-Foo:Bar)\n    "
		    @"-m  --method         "
		    @"  Set the method of the HTTP request\n    "
		    @"-o  --output         "
		    @"  Specify output file name\n    "
		    @"-O  --detect-filename"
		    @"  Do a HEAD request to detect the file name\n    "
		    @"-P  --proxy          "
		    @"  Specify SOCKS5 proxy\n    "
		    @"-q  --quiet          "
		    @"  Quiet mode (no output, except errors)\n    "
		    @"-v  --verbose        "
		    @"  Verbose mode (print headers)\n    "
		    @"    --insecure       "
		    @"  Ignore TLS errors and allow insecure redirects\n    "
		    @"    --ignore-status  "
		    @"  Ignore HTTP status code")];
	}

	[OFApplication terminateWithStatus: status];
}

static OFString *
fileNameFromContentDisposition(OFString *contentDisposition)
{
	void *pool;
	const char *UTF8String;
	size_t UTF8StringLength;
	enum {
		DISPOSITION_TYPE,
		DISPOSITION_TYPE_SEMICOLON,
		DISPOSITION_PARAM_NAME_SKIP_SPACE,
		DISPOSITION_PARAM_NAME,
		DISPOSITION_PARAM_VALUE,
		DISPOSITION_PARAM_QUOTED,
		DISPOSITION_PARAM_UNQUOTED,
		DISPOSITION_EXPECT_SEMICOLON
	} state;
	size_t last;
	OFString *type = nil, *paramName = nil, *paramValue;
	OFMutableDictionary *params;
	OFString *fileName;

	if (contentDisposition == nil)
		return nil;

	pool = objc_autoreleasePoolPush();

	UTF8String = contentDisposition.UTF8String;
	UTF8StringLength = contentDisposition.UTF8StringLength;
	state = DISPOSITION_TYPE;
	params = [OFMutableDictionary dictionary];
	last = 0;

	for (size_t i = 0; i < UTF8StringLength; i++) {
		switch (state) {
		case DISPOSITION_TYPE:
			if (UTF8String[i] == ';' || UTF8String[i] == ' ') {
				type = [OFString
				    stringWithUTF8String: UTF8String
						  length: i];

				state = (UTF8String[i] == ';'
				    ? DISPOSITION_PARAM_NAME_SKIP_SPACE
				    : DISPOSITION_TYPE_SEMICOLON);
				last = i + 1;
			}
			break;
		case DISPOSITION_TYPE_SEMICOLON:
			if (UTF8String[i] == ';') {
				state = DISPOSITION_PARAM_NAME_SKIP_SPACE;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		case DISPOSITION_PARAM_NAME_SKIP_SPACE:
			if (UTF8String[i] != ' ') {
				state = DISPOSITION_PARAM_NAME;
				last = i;
				i--;
			}
			break;
		case DISPOSITION_PARAM_NAME:
			if (UTF8String[i] == '=') {
				paramName = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				state = DISPOSITION_PARAM_VALUE;
			}
			break;
		case DISPOSITION_PARAM_VALUE:
			if (UTF8String[i] == '"') {
				state = DISPOSITION_PARAM_QUOTED;
				last = i + 1;
			} else {
				state = DISPOSITION_PARAM_UNQUOTED;
				last = i;
				i--;
			}
			break;
		case DISPOSITION_PARAM_QUOTED:
			if (UTF8String[i] == '"') {
				paramValue = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				[params setObject: paramValue
					   forKey: paramName.lowercaseString];

				state = DISPOSITION_EXPECT_SEMICOLON;
			}
			break;
		case DISPOSITION_PARAM_UNQUOTED:
			if (UTF8String[i] <= 31 || UTF8String[i] >= 127)
				return nil;

			switch (UTF8String[i]) {
			case ' ': case '"': case '(': case ')': case ',':
			case '/': case ':': case '<': case '=': case '>':
			case '?': case '@': case '[': case '\\': case ']':
			case '{': case '}':
				return nil;
			case ';':
				paramValue = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				[params setObject: paramValue
					   forKey: paramName.lowercaseString];

				state = DISPOSITION_PARAM_NAME_SKIP_SPACE;
				break;
			}
			break;
		case DISPOSITION_EXPECT_SEMICOLON:
			if (UTF8String[i] == ';') {
				state = DISPOSITION_PARAM_NAME_SKIP_SPACE;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		}
	}

	if (state == DISPOSITION_PARAM_UNQUOTED) {
		paramValue = [OFString
		    stringWithUTF8String: UTF8String + last
				  length: UTF8StringLength - last];

		[params setObject: paramValue
			   forKey: paramName.lowercaseString];
	} else if (state != DISPOSITION_EXPECT_SEMICOLON) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if (![type isEqual: @"attachment"] ||
	    (fileName = [params objectForKey: @"filename"]) == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	fileName = fileName.lastPathComponent;

	[fileName retain];
	objc_autoreleasePoolPop(pool);
	return [fileName autorelease];
}

@implementation OFHTTP
#ifdef OF_HAVE_PLUGINS
+ (void)initialize
{
	if (self != [OFHTTP class])
		return;

	/* Opportunistically try loading ObjOpenSSL and ignore any errors. */
	of_dlopen(@"objopenssl", OF_RTLD_LAZY);
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
		_method = OF_HTTP_REQUEST_METHOD_GET;

		_clientHeaders = [[OFMutableDictionary alloc]
		    initWithObject: @"OFHTTP"
			    forKey: @"User-Agent"];

		_HTTPClient = [[OFHTTPClient alloc] init];
		_HTTPClient.delegate = self;

		_buffer = of_malloc(1, [OFSystemInfo pageSize]);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)addHeader: (OFString *)header
{
	size_t pos = [header rangeOfString: @":"].location;
	OFString *name, *value;

	if (pos == OF_NOT_FOUND) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_header",
		    @"%[prog]: Headers must to be in format name:value!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	name = [header substringToIndex: pos]
	    .stringByDeletingEnclosingWhitespaces;

	value = [header substringFromIndex: pos + 1]
	    .stringByDeletingEnclosingWhitespaces;

	[_clientHeaders setObject: value
			   forKey: name];
}

- (void)setBody: (OFString *)path
{
	OFString *contentLength = nil;

	[_body release];
	_body = nil;

	if ([path isEqual: @"-"])
		_body = [of_stdin copy];
	else {
		_body = [[OFFile alloc] initWithPath: path
						mode: @"r"];

		@try {
			unsigned long long fileSize =
			    [[OFFileManager defaultManager]
			    attributesOfItemAtPath: path].fileSize;

			contentLength =
			    [OFString stringWithFormat: @"%ju", fileSize];
			[_clientHeaders setObject: contentLength
					   forKey: @"Content-Length"];
		} @catch (OFRetrieveItemAttributesFailedException *e) {
		}
	}

	if (contentLength == nil)
		[_clientHeaders setObject: @"chunked"
				   forKey: @"Transfer-Encoding"];
}

- (void)setMethod: (OFString *)method
{
	void *pool = objc_autoreleasePoolPush();

	method = method.uppercaseString;

	@try {
		_method = of_http_request_method_from_string(method);
	} @catch (OFInvalidArgumentException *e) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_method",
		    @"%[prog]: Invalid request method %[method]!",
		    @"prog", [OFApplication programName],
		    @"method", method)];
		[OFApplication terminateWithStatus: 1];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setProxy: (OFString *)proxy
{
	@try {
		size_t pos = [proxy
		    rangeOfString: @":"
			  options: OF_STRING_SEARCH_BACKWARDS].location;
		OFString *host;
		unsigned long long port;

		if (pos == OF_NOT_FOUND)
			@throw [OFInvalidFormatException exception];

		host = [proxy substringToIndex: pos];
		port = [proxy substringFromIndex: pos + 1]
		    .unsignedLongLongValue;

		if (port > UINT16_MAX)
			@throw [OFOutOfRangeException exception];

		[OFTCPSocket setSOCKS5Host: host];
		[OFTCPSocket setSOCKS5Port: (uint16_t)port];
	} @catch (OFInvalidFormatException *e) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_proxy",
		    @"%[prog]: Proxy must to be in format host:port!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}
}

- (void)applicationDidFinishLaunching
{
	OFString *outputPath;
	const of_options_parser_option_t options[] = {
		{ 'b', @"body",	1, NULL, NULL },
		{ 'c', @"continue", 0, &_continue, NULL },
		{ 'f', @"force", 0, &_force, NULL },
		{ 'h', @"help",	0, NULL, NULL },
		{ 'H', @"header", 1, NULL, NULL },
		{ 'm', @"method", 1, NULL, NULL },
		{ 'o', @"output", 1, NULL, &outputPath },
		{ 'O', @"detect-filename", 0, &_detectFileName, NULL },
		{ 'P', @"socks5-proxy", 1, NULL, NULL },
		{ 'q', @"quiet", 0, &_quiet, NULL },
		{ 'v', @"verbose", 0, &_verbose, NULL },
		{ '\0', @"insecure", 0, &_insecure, NULL },
		{ '\0', @"ignore-status", 0, &_ignoreStatus, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	of_unichar_t option;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [OFSandbox sandbox];
	sandbox.allowsStdIO = true;
	sandbox.allowsReadingFiles = true;
	sandbox.allowsWritingFiles = true;
	sandbox.allowsCreatingFiles = true;
	sandbox.allowsIPSockets = true;
	sandbox.allowsDNS = true;
	sandbox.allowsUserDatabaseReading = true;
	sandbox.allowsTTY = true;
	/* Dropped after parsing options */
	sandbox.allowsUnveil = true;

	[OFApplication activateSandbox: sandbox];
#endif

#ifndef OF_AMIGAOS
	[OFLocale addLanguageDirectory: @LANGUAGE_DIR];
#else
	[OFLocale addLanguageDirectory: @"PROGDIR:/share/ofhttp/lang"];
#endif

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'b':
			[self setBody: optionsParser.argument];
			break;
		case 'h':
			help(of_stdout, true, 0);
			break;
		case 'H':
			[self addHeader: optionsParser.argument];
			break;
		case 'm':
			[self setMethod: optionsParser.argument];
			break;
		case 'P':
			[self setProxy: optionsParser.argument];
			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[of_stderr writeLine:
				    OF_LOCALIZED(@"long_argument_missing",
				    @"%[prog]: Argument for option --%[opt] "
				    @"missing"
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%c",
				    optionsParser.lastOption];
				[of_stderr writeLine:
				    OF_LOCALIZED(@"argument_missing",
				    @"%[prog]: Argument for option -%[opt] "
				    @"missing",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		case '=':
			[of_stderr writeLine:
			    OF_LOCALIZED(@"option_takes_no_argument",
			    @"%[prog]: Option --%[opt] takes no argument",
			    @"prog", [OFApplication programName],
			    @"opt", optionsParser.lastLongOption)];

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if (optionsParser.lastLongOption != nil)
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unknown_long_option",
				    @"%[prog]: Unknown option: --%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%c",
				    optionsParser.lastOption];
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

#ifdef OF_HAVE_SANDBOX
	[sandbox unveilPath: (outputPath != nil
				 ? outputPath : OF_PATH_CURRENT_DIRECTORY)
		permissions: (_continue ? @"rwc" : @"wc")];
	/* In case we use ObjOpenSSL for https later */
	[sandbox unveilPath: @"/etc/ssl"
		permissions: @"r"];

	sandbox.allowsUnveil = false;
	[OFApplication activateSandbox: sandbox];
#endif

	_outputPath = [outputPath copy];
	_URLs = [optionsParser.remainingArguments copy];

	if (_URLs.count < 1)
		help(of_stderr, false, 1);

	if (_quiet && _verbose) {
		[of_stderr writeLine: OF_LOCALIZED(@"quiet_xor_verbose",
		    @"%[prog]: -q / --quiet and -v / --verbose are mutually "
		    @"exclusive!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_outputPath != nil && _detectFileName) {
		[of_stderr writeLine: OF_LOCALIZED(
		    @"output_xor_detect_filename",
		    @"%[prog]: -o / --output and -O / --detect-filename are "
		    @"mutually exclusive!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_outputPath != nil && _URLs.count > 1) {
		[of_stderr writeLine:
		    OF_LOCALIZED(@"output_only_with_one_url",
		    @"%[prog]: Cannot use -o / --output when more than one URL "
		    @"has been specified!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_insecure)
		_HTTPClient.allowsInsecureRedirects = true;

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

-    (void)client: (OFHTTPClient *)client
  didCreateSocket: (OFTCPSocket *)sock
	  request: (OFHTTPRequest *)request
{
	if (_insecure && [sock respondsToSelector:
	    @selector(setVerifiesCertificates:)])
		((id <OFTLSSocket>)sock).verifiesCertificates = false;
}

-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	/* TODO: Do asynchronously and print status */
	while (!_body.atEndOfStream) {
		char buffer[4096];
		size_t length;

		length = [_body readIntoBuffer: buffer
					length: 4096];
		[body writeBuffer: buffer
			   length: length];
	}
}

-	  (bool)client: (OFHTTPClient *)client
  shouldFollowRedirect: (OFURL *)URL
	    statusCode: (short)statusCode
	       request: (OFHTTPRequest *)request
	      response: (OFHTTPResponse *)response
{
	if (_verbose) {
		void *pool = objc_autoreleasePoolPush();
		OFDictionary OF_GENERIC(OFString *, OFString *) *headers =
		    response.headers;
		OFEnumerator *keyEnumerator = [headers keyEnumerator];
		OFEnumerator *objectEnumerator = [headers objectEnumerator];
		OFString *key, *object;

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[of_stdout writeFormat: @"  %@: %@\n",
						key, object];

		objc_autoreleasePoolPop(pool);
	}

	if (!_quiet)
		[of_stdout writeFormat: @"☇ %@", URL.string];

	_length = 0;

	return true;
}

-      (bool)stream: (OFStream *)response
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception != nil) {
		OFString *URL;

		[_progressBar stop];
		[_progressBar draw];
		[_progressBar release];
		_progressBar = nil;

		if (!_quiet) {
			[of_stdout writeString: @"\n  "];
			[of_stdout writeLine: OF_LOCALIZED(@"download_error",
			    @"Error!")];
		}

		URL = [_URLs objectAtIndex: _URLIndex - 1];
		[of_stderr writeLine: OF_LOCALIZED(
		    @"download_failed_exception",
		    @"%[prog]: Failed to download <%[url]>!\n"
		    @"  %[exception]",
		    @"prog", [OFApplication programName],
		    @"url", URL,
		    @"exception", exception)];

		_errorCode = 1;
		[self performSelector: @selector(downloadNextURL)
			   afterDelay: 0];
		return false;
	}

	_received += length;

	[_output writeBuffer: buffer
		      length: length];

	[_progressBar setReceived: _received];

	if (response.atEndOfStream) {
		[_progressBar stop];
		[_progressBar draw];
		[_progressBar release];
		_progressBar = nil;

		if (!_quiet) {
			[of_stdout writeString: @"\n  "];
			[of_stdout writeLine:
			    OF_LOCALIZED(@"download_done", @"Done!")];
		}

		[self performSelector: @selector(downloadNextURL)
			   afterDelay: 0];
		return false;
	}

	return true;
}

-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
	 statusCode: (short)statusCode
	    request: (OFHTTPRequest *)request
{
	if (statusCode != 206)
		_resumedFrom = 0;

	if (!_quiet) {
		OFString *lengthString =
		    [headers objectForKey: @"Content-Length"];
		OFString *type = [headers objectForKey: @"Content-Type"];

		[of_stdout writeFormat: @" ➜ %hd\n", statusCode];

		if (type == nil)
			type = OF_LOCALIZED(@"type_unknown", @"unknown");

		if (lengthString != nil) {
			_length = lengthString.unsignedLongLongValue;

			if (_resumedFrom + _length >= GIBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / GIBIBYTE];
				lengthString = OF_LOCALIZED(@"size_gib",
				    @"%[num] GiB",
				    @"num", lengthString);
			} else if (_resumedFrom + _length >= MEBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / MEBIBYTE];
				lengthString = OF_LOCALIZED(@"size_mib",
				    @"%[num] MiB",
				    @"num", lengthString);
			} else if (_resumedFrom + _length >= KIBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / KIBIBYTE];
				lengthString = OF_LOCALIZED(@"size_kib",
				    @"%[num] KiB",
				    @"num", lengthString);
			} else {
				lengthString = [OFString stringWithFormat:
				    @"%jd", _resumedFrom + _length];
				lengthString = OF_LOCALIZED(@"size_bytes",
				    @"["
				    @"    ["
				    @"        {'num == 1': '1 byte'},"
				    @"        {'': '%[num] bytes'}"
				    @"    ]"
				    @"]".objectByParsingJSON,
				    @"num", lengthString);
			}
		} else
			lengthString =
			    OF_LOCALIZED(@"size_unknown", @"unknown");

		if (_verbose) {
			void *pool = objc_autoreleasePoolPush();
			OFEnumerator OF_GENERIC(OFString *) *keyEnumerator =
			    [headers keyEnumerator];
			OFEnumerator OF_GENERIC(OFString *) *objectEnumerator =
			    [headers objectEnumerator];
			OFString *key, *object;

			if (statusCode / 100 == 2 && _currentFileName != nil) {
				[of_stdout writeString: @"  "];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"info_name_unaligned",
				    @"Name: %[name]",
				    @"name", _currentFileName)];
			}

			while ((key = [keyEnumerator nextObject]) != nil &&
			    (object = [objectEnumerator nextObject]) != nil)
				[of_stdout writeFormat: @"  %@: %@\n",
							key, object];

			objc_autoreleasePoolPop(pool);
		} else if (statusCode / 100 == 2 && !_detectFileNameRequest) {
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_name",
			    @"Name: %[name]",
			    @"name", _currentFileName)];
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_type",
			    @"Type: %[type]",
			    @"type", type)];
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_size",
			    @"Size: %[size]",
			    @"size", lengthString)];
		}
	}
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	if (exception != nil) {
		if ([exception isKindOfClass:
		    [OFResolveHostFailedException class]]) {
			if (!_quiet)
				[of_stdout writeString: @"\n"];

			[of_stderr writeLine:
			    OF_LOCALIZED(@"download_resolve_host_failed",
			    @"%[prog]: Failed to download <%[url]>!\n"
			    @"  Failed to resolve host: %[exception]",
			    @"prog", [OFApplication programName],
			    @"url", request.URL.string,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFConnectionFailedException class]]) {
			if (!_quiet)
				[of_stdout writeString: @"\n"];

			[of_stderr writeLine:
			    OF_LOCALIZED(@"download_failed_connection_failed",
			    @"%[prog]: Failed to download <%[url]>!\n"
			    @"  Connection failed: %[exception]",
			    @"prog", [OFApplication programName],
			    @"url", request.URL.string,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFInvalidServerReplyException class]]) {
			if (!_quiet)
				[of_stdout writeString: @"\n"];

			[of_stderr writeLine: OF_LOCALIZED(
			    @"download_failed_invalid_server_reply",
			    @"%[prog]: Failed to download <%[url]>!\n"
			    @"  Invalid server reply!",
			    @"prog", [OFApplication programName],
			    @"url", request.URL.string)];
		} else if ([exception isKindOfClass:
		    [OFUnsupportedProtocolException class]]) {
			if (!_quiet)
				[of_stdout writeString: @"\n"];

			[of_stderr writeLine: OF_LOCALIZED(@"no_ssl_library",
			    @"%[prog]: No TLS library loaded!\n"
			    @"  In order to download via https, you need to "
			    @"preload an TLS library for ObjFW\n"
			    @"  such as ObjOpenSSL!",
			    @"prog", [OFApplication programName])];
		} else if ([exception isKindOfClass:
		    [OFReadOrWriteFailedException class]]) {
			OFString *error = OF_LOCALIZED(
			    @"download_failed_read_or_write_failed_any",
			    @"Read or write failed");

			if (!_quiet)
				[of_stdout writeString: @"\n"];

			if ([exception isKindOfClass:
			    [OFReadFailedException class]])
				error = OF_LOCALIZED(
				    @"download_failed_read_or_write_failed_"
				    @"read",
				    @"Read failed");
			else if ([exception isKindOfClass:
			    [OFWriteFailedException class]])
				error = OF_LOCALIZED(
				    @"download_failed_read_or_write_failed_"
				    @"write",
				    @"Write failed");

			[of_stderr writeLine: OF_LOCALIZED(
			    @"download_failed_read_or_write_failed",
			    @"%[prog]: Failed to download <%[url]>!\n"
			    @"  %[error]: %[exception]",
			    @"prog", [OFApplication programName],
			    @"url", request.URL.string,
			    @"error", error,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFHTTPRequestFailedException class]]) {
			short statusCode;
			OFString *codeString;

			if (_ignoreStatus) {
				exception = nil;
				goto after_exception_handling;
			}

			statusCode = response.statusCode;
			codeString = [OFString stringWithFormat: @"%hd %@",
			    statusCode,
			    of_http_status_code_to_string(statusCode)];
			[of_stderr writeLine: OF_LOCALIZED(@"download_failed",
			    @"%[prog]: Failed to download <%[url]>!\n"
			    @"  HTTP status code: %[code]",
			    @"prog", [OFApplication programName],
			    @"url", request.URL.string,
			    @"code", codeString)];
		} else
			@throw exception;

		_errorCode = 1;
		[self performSelector: @selector(downloadNextURL)
			   afterDelay: 0];
		return;
	}

after_exception_handling:
	if (_method == OF_HTTP_REQUEST_METHOD_HEAD)
		goto next;

	if (_detectFileNameRequest) {
		_currentFileName = [fileNameFromContentDisposition(
		    [response.headers objectForKey: @"Content-Disposition"])
		    copy];
		_detectedFileName = true;

		/* Handle this URL on the next -[downloadNextURL] call */
		_URLIndex--;

		[self performSelector: @selector(downloadNextURL)
			   afterDelay: 0];
		return;
	}

	if ([_outputPath isEqual: @"-"])
		_output = of_stdout;
	else {
		if (!_continue && !_force && [[OFFileManager defaultManager]
		    fileExistsAtPath: _currentFileName]) {
			[of_stderr writeLine:
			    OF_LOCALIZED(@"output_already_exists",
			    @"%[prog]: File %[filename] already exists!",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName)];

			_errorCode = 1;
			goto next;
		}

		@try {
			OFString *mode =
			    (response.statusCode == 206 ? @"a" : @"w");
			_output = [[OFFile alloc] initWithPath: _currentFileName
							  mode: mode];
		} @catch (OFOpenItemFailedException *e) {
			[of_stderr writeLine:
			    OF_LOCALIZED(@"failed_to_open_output",
			    @"%[prog]: Failed to open file %[filename]: "
			    @"%[exception]",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName,
			    @"exception", e)];

			_errorCode = 1;
			goto next;
		}
	}

	if (!_quiet) {
		_progressBar = [[ProgressBar alloc]
		    initWithLength: _length
		       resumedFrom: _resumedFrom];
		[_progressBar setReceived: _received];
		[_progressBar draw];
	}

	[_currentFileName release];
	_currentFileName = nil;

	response.delegate = self;
	[response asyncReadIntoBuffer: _buffer
			       length: [OFSystemInfo pageSize]];
	return;

next:
	[_currentFileName release];
	_currentFileName = nil;

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

- (void)downloadNextURL
{
	OFString *URLString = nil;
	OFURL *URL;
	OFMutableDictionary *clientHeaders;
	OFHTTPRequest *request;

	_received = _length = _resumedFrom = 0;

	if (_output != of_stdout)
		[_output release];
	_output = nil;

	if (_URLIndex >= _URLs.count)
		[OFApplication terminateWithStatus: _errorCode];

	@try {
		URLString = [_URLs objectAtIndex: _URLIndex++];
		URL = [OFURL URLWithString: URLString];
	} @catch (OFInvalidFormatException *e) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_url",
		    @"%[prog]: Invalid URL: <%[url]>!",
		    @"prog", [OFApplication programName],
		    @"url", URLString)];

		_errorCode = 1;
		goto next;
	}

	if (![URL.scheme isEqual: @"http"] && ![URL.scheme isEqual: @"https"]) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_scheme",
		    @"%[prog]: Invalid scheme: <%[url]>!",
		    @"prog", [OFApplication programName],
		    @"url", URLString)];

		_errorCode = 1;
		goto next;
	}

	clientHeaders = [[_clientHeaders mutableCopy] autorelease];

	if (_detectFileName && !_detectedFileName) {
		if (!_quiet)
			[of_stdout writeFormat: @"⠒ %@", URL.string];

		request = [OFHTTPRequest requestWithURL: URL];
		request.headers = clientHeaders;
		request.method = OF_HTTP_REQUEST_METHOD_HEAD;

		_detectFileNameRequest = true;
		[_HTTPClient asyncPerformRequest: request];
		return;
	}

	if (!_detectedFileName) {
		[_currentFileName release];
		_currentFileName = nil;
	} else
		_detectedFileName = false;

	if (_currentFileName == nil)
		_currentFileName = [_outputPath copy];

	if (_currentFileName == nil)
		_currentFileName = [URL.path.lastPathComponent copy];

	if (_continue) {
		@try {
			unsigned long long size =
			    [[OFFileManager defaultManager]
			    attributesOfItemAtPath: _currentFileName].fileSize;
			OFString *range;

			if (size > ULLONG_MAX)
				@throw [OFOutOfRangeException exception];

			_resumedFrom = (unsigned long long)size;

			range = [OFString stringWithFormat: @"bytes=%jd-",
							    _resumedFrom];
			[clientHeaders setObject: range
					  forKey: @"Range"];
		} @catch (OFRetrieveItemAttributesFailedException *e) {
		}
	}

	if (!_quiet)
		[of_stdout writeFormat: @"⇣ %@", URL.string];

	request = [OFHTTPRequest requestWithURL: URL];
	request.headers = clientHeaders;
	request.method = _method;

	_detectFileNameRequest = false;
	[_HTTPClient asyncPerformRequest: request];
	return;

next:
	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}
@end
