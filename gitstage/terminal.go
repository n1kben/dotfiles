package main

import (
	"os"
	"os/signal"
	"syscall"
	"unsafe"
)

// termios mirrors the C struct termios for Linux.
type termios struct {
	Iflag  uint32
	Oflag  uint32
	Cflag  uint32
	Lflag  uint32
	Line   uint8
	Cc     [32]uint8
	Ispeed uint32
	Ospeed uint32
}

// winsize mirrors the C struct winsize.
type winsize struct {
	Row uint16
	Col uint16
	X   uint16
	Y   uint16
}

const (
	tcGets    = 0x5401 // TCGETS
	tcSets    = 0x5402 // TCSETS
	tiocgwinsz = 0x5413 // TIOCGWINSZ

	// Input flags
	iBRKINT = 0x0002
	iICRNL  = 0x0100
	iINPCK  = 0x0010
	iISTRIP = 0x0020
	iIXON   = 0x0400

	// Output flags
	oOPOST = 0x0001

	// Local flags
	lECHO   = 0x0008
	lICANON = 0x0002
	lIEXTEN = 0x8000
	lISIG   = 0x0001

	// Control flags
	cCS8 = 0x0030

	vMIN  = 6
	vTIME = 5
)

var origTermios termios

func tcGetAttr(fd uintptr, t *termios) error {
	_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, tcGets, uintptr(unsafe.Pointer(t)))
	if errno != 0 {
		return errno
	}
	return nil
}

func tcSetAttr(fd uintptr, t *termios) error {
	_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, tcSets, uintptr(unsafe.Pointer(t)))
	if errno != 0 {
		return errno
	}
	return nil
}

func enableRawMode() error {
	fd := os.Stdin.Fd()
	if err := tcGetAttr(fd, &origTermios); err != nil {
		return err
	}
	raw := origTermios
	raw.Iflag &^= iBRKINT | iICRNL | iINPCK | iISTRIP | iIXON
	raw.Oflag &^= oOPOST
	raw.Lflag &^= lECHO | lICANON | lIEXTEN | lISIG
	raw.Cflag |= cCS8
	raw.Cc[vMIN] = 1
	raw.Cc[vTIME] = 0
	return tcSetAttr(fd, &raw)
}

func disableRawMode() {
	tcSetAttr(os.Stdin.Fd(), &origTermios)
}

func enterAltScreen() {
	os.Stdout.WriteString("\x1b[?1049h")
}

func exitAltScreen() {
	os.Stdout.WriteString("\x1b[?1049l")
}

func getTerminalSize() (int, int) {
	var ws winsize
	_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, os.Stdout.Fd(), tiocgwinsz, uintptr(unsafe.Pointer(&ws)))
	if errno != 0 || ws.Col == 0 || ws.Row == 0 {
		return 80, 24
	}
	return int(ws.Col), int(ws.Row)
}

func listenForResize(ch chan<- os.Signal) {
	signal.Notify(ch, syscall.SIGWINCH)
}

func readKey() KeyAction {
	var buf [8]byte
	n, err := os.Stdin.Read(buf[:])
	if err != nil || n == 0 {
		return KeyNone
	}

	// Single byte
	if n == 1 {
		switch buf[0] {
		case 0x0A: // Ctrl-J (line feed)
			return KeyCtrlJ
		case 0x0B: // Ctrl-K (vertical tab)
			return KeyCtrlK
		case 0x0D: // Enter (carriage return)
			return KeyEnter
		case 0x09: // Tab
			return KeyTab
		case 0x1B: // Esc
			return KeyEsc
		case 0x6A: // j
			return KeyJ
		case 0x6B: // k
			return KeyK
		case 0x71: // q
			return KeyQ
		}
		return KeyNone
	}

	// Escape sequences (3+ bytes starting with ESC [)
	if n >= 3 && buf[0] == 0x1B && buf[1] == 0x5B {
		if buf[2] == 0x5A { // Shift-Tab: ESC [ Z
			return KeyShiftTab
		}
		// Unknown escape sequence - treat as Esc
		return KeyEsc
	}

	// Multi-byte starting with ESC but not ESC [
	if buf[0] == 0x1B {
		return KeyEsc
	}

	return KeyNone
}
