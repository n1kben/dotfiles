package main

// termios mirrors the C struct termios for Darwin.
type termios struct {
	Iflag  uint64
	Oflag  uint64
	Cflag  uint64
	Lflag  uint64
	Cc     [20]uint8
	Ispeed uint64
	Ospeed uint64
}

const (
	tcGets     = 0x40487413 // TIOCGETA
	tcSets     = 0x80487414 // TIOCSETA
	tiocgwinsz = 0x40087468 // TIOCGWINSZ

	// Input flags
	iBRKINT = 0x0002
	iICRNL  = 0x0100
	iINPCK  = 0x0010
	iISTRIP = 0x0020
	iIXON   = 0x0200

	// Output flags
	oOPOST = 0x0001

	// Local flags
	lECHO   = 0x0008
	lICANON = 0x0100
	lIEXTEN = 0x0400
	lISIG   = 0x0080

	// Control flags
	cCS8 = 0x0300

	vMIN  = 16
	vTIME = 17
)
