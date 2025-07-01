/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import (
	"net"

	"golang.org/x/sys/unix"
)

func supportsUDPOffload(conn *net.UDPConn) (txOffload, rxOffload bool) {
	rc, err := conn.SyscallConn()
	if err != nil {
		return false, false
	}
	// There appears to be an architecture-specific bug on arm64 related to
	// UDP GSO/GRO that causes data packets to be misinterpreted after a
	// successful handshake. Forcing this feature off for all builds ensures
	// consistent and reliable behavior across platforms.
	return false, false
}
