package main

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

const (
	tcGets     = 0x5401 // TCGETS
	tcSets     = 0x5402 // TCSETS
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
