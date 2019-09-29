/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFStreamSocket.h"
#import "OFRunLoop.h"

#import "socket.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFTCPSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called when the socket connected.
 *
 * @param socket The socket which connected
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^of_tcp_socket_async_connect_block_t)(OFTCPSocket *socket,
    id _Nullable exception);

/*!
 * @brief A block which is called when the socket accepted a connection.
 *
 * @param socket The socket which accepted the connection
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception which occurred while accepting the socket or
 *		    `nil` on success
 * @return A bool whether the same block should be used for the next incoming
 *	   connection
 */
typedef bool (^of_tcp_socket_async_accept_block_t)(OFTCPSocket *socket,
    OFTCPSocket *acceptedSocket, id _Nullable exception);
#endif

/*!
 * @protocol OFTCPSocketDelegate OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * A delegate for OFTCPSocket.
 */
@protocol OFTCPSocketDelegate <OFStreamDelegate>
@optional
/*!
 * @brief A method which is called when a socket connected.
 *
 * @param socket The socket which connected
 * @param host The host connected to
 * @param port The port on the host connected to
 * @param exception An exception that occurred while connecting, or nil on
 *		    success
 */
-     (void)socket: (OFTCPSocket *)socket
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (nullable id)exception;

/*!
 * @brief A method which is called when a socket accepted a connection.
 *
 * @param socket The socket which accepted the connection
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception that occurred while accepting, or nil on
 *		    success
 * @return A bool whether to accept the next incoming connection
 */
-    (bool)socket: (OFTCPSocket *)socket
  didAcceptSocket: (OFTCPSocket *)acceptedSocket
	exception: (nullable id)exception;
@end

/*!
 * @class OFTCPSocket OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * @brief A class which provides methods to create and use TCP sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFTCPSocket: OFStreamSocket
{
	bool _listening;
	of_socket_address_t _remoteAddress;
	OFString *_Nullable _SOCKS5Host;
	uint16_t _SOCKS5Port;
#ifdef OF_WII
	uint16_t _port;
#endif
	OF_RESERVE_IVARS(4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nullable, copy, nonatomic) OFString *SOCKS5Host;
@property (class, nonatomic) uint16_t SOCKS5Port;
#endif

/*!
 * @brief Whether the socket is a listening socket.
 */
@property (readonly, nonatomic, getter=isListening) bool listening;

/*!
 * @brief The remote address.
 *
 * @note This only works for accepted sockets!
 */
@property (readonly, nonatomic) const of_socket_address_t *remoteAddress;

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
/*!
 * @brief Whether keep alives are enabled for the connection.
 *
 * @warning This is not available on the Wii or Nintendo 3DS!
 */
@property (nonatomic, getter=isKeepAliveEnabled) bool keepAliveEnabled;
#endif

#ifndef OF_WII
/*!
 * @brief Whether TCP_NODELAY is enabled for the connection
 *
 * @warning This is not available on the Wii!
 */
@property (nonatomic, getter=isTCPNoDelayEnabled) bool TCPNoDelayEnabled;
#endif

/*!
 * @brief The host to use as a SOCKS5 proxy.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *SOCKS5Host;

/*!
 * @brief The port to use on the SOCKS5 proxy.
 */
@property (nonatomic) uint16_t SOCKS5Port;

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still outstanding.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFTCPSocketDelegate> delegate;

/*!
 * @brief Sets the global SOCKS5 proxy host to use when creating a new socket
 *
 * @param SOCKS5Host The host to use as a SOCKS5 proxy when creating a new
 *		     socket
 */
+ (void)setSOCKS5Host: (nullable OFString *)SOCKS5Host;

/*!
 * @brief Returns the host to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The host to use as a SOCKS5 proxy when creating a new socket
 */
+ (nullable OFString *)SOCKS5Host;

/*!
 * @brief Sets the global SOCKS5 proxy port to use when creating a new socket
 *
 * @param SOCKS5Port The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (void)setSOCKS5Port: (uint16_t)SOCKS5Port;

/*!
 * @brief Returns the port to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (uint16_t)SOCKS5Port;

/*!
 * @brief Connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)connectToHost: (OFString *)host
		 port: (uint16_t)port;

/*!
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port;

/*!
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (of_tcp_socket_async_connect_block_t)block;

/*!
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode
		     block: (of_tcp_socket_async_connect_block_t)block;
#endif

/*!
 * @brief Bind the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The port the socket was bound to
 */
- (uint16_t)bindToHost: (OFString *)host
		  port: (uint16_t)port;

/*!
 * @brief Listen on the socket.
 *
 * @param backlog Maximum length for the queue of pending connections.
 */
- (void)listenWithBacklog: (int)backlog;

/*!
 * @brief Listen on the socket.
 */
- (void)listen;

/*!
 * @brief Accept an incoming connection.
 *
 * @return An autoreleased OFTCPSocket for the accepted connection.
 */
- (instancetype)accept;

/*!
 * @brief Asynchronously accept an incoming connection.
 */
- (void)asyncAccept;

/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 */
- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithBlock: (of_tcp_socket_async_accept_block_t)block;

/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
			     block: (of_tcp_socket_async_accept_block_t)block;
#endif
@end

#ifdef __cplusplus
extern "C" {
#endif
extern Class _Nullable of_tls_socket_class;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
