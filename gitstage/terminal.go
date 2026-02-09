package main

import (
	"os"
	"syscall"
	"unsafe"
)

// winsize mirrors the C struct winsize.
type winsize struct {
	Row uint16
	Col uint16
	X   uint16
	Y   uint16
}

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


func readKey() KeyAction {
	var buf [8]byte
	n, err := os.Stdin.Read(buf[:])
	if err != nil || n == 0 {
		return KeyNone
	}

	// Single byte
	if n == 1 {
		switch buf[0] {
		case 0x03: // Ctrl-C
			return KeyCtrlC
		case 0x0D: // Enter
			return KeyEnter
		case 0x09: // Tab
			return KeyTab
		case 0x1B: // Esc
			return KeyEsc
		case 'G':
			return KeyShiftG
		case 'J':
			return KeyShiftJ
		case 'K':
			return KeyShiftK
		case 'S':
			return KeyShiftS
		case 'c':
			return KeyC
		case 'g':
			return KeyG
		case 'h':
			return KeyH
		case 'j':
			return KeyJ
		case 'k':
			return KeyK
		case 'l':
			return KeyL
		case 'm':
			return KeyM
		case 'M':
			return KeyShiftM
		case 's':
			return KeyS
		case 'v':
			return KeyV
		case 'V':
			return KeyShiftV
		case 'q':
			return KeyQ
		case '[':
			return KeyLeftBracket
		case ']':
			return KeyRightBracket
		}
		return KeyNone
	}

	// Escape sequences (3+ bytes starting with ESC [)
	if n >= 3 && buf[0] == 0x1B && buf[1] == 0x5B {
		switch buf[2] {
		case 'A': // Up
			return KeyUp
		case 'B': // Down
			return KeyDown
		case 'C': // Right
			return KeyRight
		case 'D': // Left
			return KeyLeft
		case 'Z': // Shift-Tab
			return KeyShiftTab
		}
		return KeyNone
	}

	// Multi-byte starting with ESC but not ESC [
	if buf[0] == 0x1B {
		return KeyNone
	}

	return KeyNone
}
