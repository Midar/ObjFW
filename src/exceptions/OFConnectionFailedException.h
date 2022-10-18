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

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFConnectionFailedException \
 *	  OFConnectionFailedException.h ObjFW/OFConnectionFailedException.h
 *
 * @brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFString *_Nullable _host;
	uint16_t _port;
	OFString *_Nullable _path;
	uint32_t _network;
	unsigned char _node[IPX_NODE_LEN];
	id _socket;
	int _errNo;
	OF_RESERVE_IVARS(OFConnectionFailedException, 4)
}

/**
 * @brief The host to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *host;

/**
 * @brief The port on the host to which the connection failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief The path to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief The IPX network of the node to which the connection failed.
 */
@property (readonly, nonatomic) uint32_t network;

/**
 * @brief The IPX node to which the connection failed.
 */
@property (readonly, nonatomic) unsigned char *node;

/**
 * @brief The socket which could not connect.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param network The IPX network of the node to which the connection failed
 * @param node The node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)
    exceptionWithNetwork: (uint32_t)network
		    node: (unsigned char [_Nullable IPX_NODE_LEN])node
		    port: (uint16_t)port
		  socket: (id)socket
		   errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param network The IPX network of the node to which the connection failed
 * @param node The node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithNetwork: (uint32_t)network
			   node: (unsigned char [_Nullable IPX_NODE_LEN])node
			   port: (uint16_t)port
			 socket: (id)socket
			  errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
