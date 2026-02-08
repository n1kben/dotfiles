package main

// LineType classifies a diff line.
type LineType int

const (
	LineContext LineType = iota
	LineAdd
	LineRemove
)

// DiffLine represents a single line in a diff hunk.
type DiffLine struct {
	Content string   // raw line text including +/- prefix
	Type    LineType // context, add, or remove
	Staged  bool
}

// Hunk represents a single diff hunk.
type Hunk struct {
	OrigStart int // from @@ header
	OrigCount int
	NewStart  int
	NewCount  int
	Lines     []DiffLine
}

// FileStatus classifies a file in the working tree.
type FileStatus int

const (
	StatusModified  FileStatus = iota
	StatusDeleted
	StatusUntracked
)

// DiffFile represents a file with its diff hunks.
type DiffFile struct {
	Path    string
	Status  FileStatus
	Hunks   []Hunk
	Touched bool // set when user toggles any line
}

// DisplayLine is a flattened view entry for rendering.
type DisplayLine struct {
	HunkIdx        int       // which hunk
	LineIdx        int       // index within hunk (-1 for header rows)
	Line           *DiffLine // pointer to real data (nil for headers)
	IsHunkHeader   bool
	HunkHeaderText string // e.g. "@@ -10,6 +10,7 @@"
}

// KeyAction represents a parsed key press.
type KeyAction int

const (
	KeyNone KeyAction = iota
	KeyJ
	KeyK
	KeyCtrlJ
	KeyCtrlK
	KeyTab
	KeyShiftTab
	KeyEnter
	KeyEsc
	KeyQ
)
