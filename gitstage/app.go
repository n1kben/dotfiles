package main

import (
	"fmt"
	"os"
	"time"
)

// AppState holds the full application state.
type AppState struct {
	Files            []DiffFile
	FileIdx          int
	FileScrollOffset int
	LineIdx          int
	ScrollOffset     int
	DisplayLines     []DisplayLine
	Width            int
	Height           int
	DiffFocused      bool
	PendingKey       KeyAction
	VisualMode       bool
	VisualAnchor     int
}

// buildDisplayLines flattens the current file's hunks into display lines.
func (s *AppState) buildDisplayLines() {
	s.DisplayLines = nil
	if s.FileIdx < 0 || s.FileIdx >= len(s.Files) {
		return
	}
	f := &s.Files[s.FileIdx]
	for hi, h := range f.Hunks {
		// Hunk header
		header := fmt.Sprintf("@@ -%d,%d +%d,%d @@", h.OrigStart, h.OrigCount, h.NewStart, h.NewCount)
		s.DisplayLines = append(s.DisplayLines, DisplayLine{
			HunkIdx:        hi,
			LineIdx:        -1,
			IsHunkHeader:   true,
			HunkHeaderText: header,
		})
		// Diff lines
		for li := range h.Lines {
			s.DisplayLines = append(s.DisplayLines, DisplayLine{
				HunkIdx: hi,
				LineIdx: li,
				Line:    &f.Hunks[hi].Lines[li],
			})
		}
	}
}

// firstStageableLine returns the index of the first stageable display line, or 0.
func (s *AppState) firstStageableLine() int {
	for i, dl := range s.DisplayLines {
		if dl.Line != nil && (dl.Line.Type == LineAdd || dl.Line.Type == LineRemove) {
			return i
		}
	}
	// If no stageable line, return first non-header
	for i, dl := range s.DisplayLines {
		if !dl.IsHunkHeader {
			return i
		}
	}
	return 0
}

// firstNonHeaderLine returns the index of the first non-header display line, or 0.
func (s *AppState) firstNonHeaderLine() int {
	for i, dl := range s.DisplayLines {
		if !dl.IsHunkHeader {
			return i
		}
	}
	return 0
}

// adjustFileScroll ensures the selected file is visible in the left pane.
func (s *AppState) adjustFileScroll() {
	contentHeight := s.Height - 3
	if contentHeight < 1 {
		contentHeight = 1
	}
	if s.FileIdx < s.FileScrollOffset {
		s.FileScrollOffset = s.FileIdx
	}
	if s.FileIdx >= s.FileScrollOffset+contentHeight {
		s.FileScrollOffset = s.FileIdx - contentHeight + 1
	}
}

// adjustScroll ensures the cursor is visible within the right pane.
func (s *AppState) adjustScroll() {
	contentHeight := s.Height - 3
	if contentHeight < 1 {
		contentHeight = 1
	}
	if s.LineIdx < s.ScrollOffset {
		s.ScrollOffset = s.LineIdx
	}
	if s.LineIdx >= s.ScrollOffset+contentHeight {
		s.ScrollOffset = s.LineIdx - contentHeight + 1
	}
}

// moveDown moves the cursor to the next non-header display line.
func (s *AppState) moveDown() {
	for i := s.LineIdx + 1; i < len(s.DisplayLines); i++ {
		if !s.DisplayLines[i].IsHunkHeader {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
}

// moveUp moves the cursor to the previous non-header display line.
func (s *AppState) moveUp() {
	for i := s.LineIdx - 1; i >= 0; i-- {
		if !s.DisplayLines[i].IsHunkHeader {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
}

// selectFile switches to the given file index.
func (s *AppState) selectFile(idx int) {
	if idx < 0 {
		idx = 0
	}
	if idx >= len(s.Files) {
		idx = len(s.Files) - 1
	}
	if idx == s.FileIdx {
		return
	}
	s.VisualMode = false
	s.FileIdx = idx
	s.adjustFileScroll()
	s.buildDisplayLines()
	s.ScrollOffset = 0
	s.LineIdx = s.firstStageableLine()
	s.adjustScroll()
}

// moveDownN moves down n non-header lines.
func (s *AppState) moveDownN(n int) {
	for i := 0; i < n; i++ {
		s.moveDown()
	}
}

// moveUpN moves up n non-header lines.
func (s *AppState) moveUpN(n int) {
	for i := 0; i < n; i++ {
		s.moveUp()
	}
}

// diffFirst jumps to the first non-header display line.
func (s *AppState) diffFirst() {
	s.LineIdx = s.firstNonHeaderLine()
	s.adjustScroll()
}

// diffLast jumps to the last non-header display line.
func (s *AppState) diffLast() {
	for i := len(s.DisplayLines) - 1; i >= 0; i-- {
		if !s.DisplayLines[i].IsHunkHeader {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
}

// toggleLine toggles the staged state of the current line.
func (s *AppState) toggleLine() {
	if s.LineIdx < 0 || s.LineIdx >= len(s.DisplayLines) {
		return
	}
	dl := &s.DisplayLines[s.LineIdx]
	if dl.Line == nil || (dl.Line.Type != LineAdd && dl.Line.Type != LineRemove) {
		return
	}

	dl.Line.Staged = !dl.Line.Staged
	s.Files[s.FileIdx].Touched = true
}

// toggleVisualSelection toggles all stageable lines in the visual selection range.
func (s *AppState) toggleVisualSelection() {
	lo, hi := s.VisualAnchor, s.LineIdx
	if lo > hi {
		lo, hi = hi, lo
	}

	// Check if any stageable line in range is unstaged
	anyUnstaged := false
	for i := lo; i <= hi; i++ {
		dl := &s.DisplayLines[i]
		if dl.Line != nil && (dl.Line.Type == LineAdd || dl.Line.Type == LineRemove) {
			if !dl.Line.Staged {
				anyUnstaged = true
				break
			}
		}
	}

	newState := anyUnstaged
	for i := lo; i <= hi; i++ {
		dl := &s.DisplayLines[i]
		if dl.Line != nil && (dl.Line.Type == LineAdd || dl.Line.Type == LineRemove) {
			dl.Line.Staged = newState
		}
	}

	s.Files[s.FileIdx].Touched = true
	s.VisualMode = false
}

// nextHunk jumps to the first non-header line of the next hunk.
func (s *AppState) nextHunk() {
	if len(s.DisplayLines) == 0 {
		return
	}
	cur := s.DisplayLines[s.LineIdx].HunkIdx
	for i := s.LineIdx + 1; i < len(s.DisplayLines); i++ {
		if s.DisplayLines[i].HunkIdx > cur && !s.DisplayLines[i].IsHunkHeader {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
}

// prevHunk jumps to the first non-header line of the previous hunk.
func (s *AppState) prevHunk() {
	if len(s.DisplayLines) == 0 {
		return
	}
	cur := s.DisplayLines[s.LineIdx].HunkIdx
	if cur == 0 {
		return
	}
	for i := 0; i < len(s.DisplayLines); i++ {
		if s.DisplayLines[i].HunkIdx == cur-1 && !s.DisplayLines[i].IsHunkHeader {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
}

// stageCurrentFile toggles all stageable lines in the current file.
func (s *AppState) stageCurrentFile() {
	if s.FileIdx < 0 || s.FileIdx >= len(s.Files) {
		return
	}
	f := &s.Files[s.FileIdx]

	anyUnstaged := false
	for hi := range f.Hunks {
		for li := range f.Hunks[hi].Lines {
			l := &f.Hunks[hi].Lines[li]
			if (l.Type == LineAdd || l.Type == LineRemove) && !l.Staged {
				anyUnstaged = true
				break
			}
		}
		if anyUnstaged {
			break
		}
	}

	newState := anyUnstaged
	for hi := range f.Hunks {
		for li := range f.Hunks[hi].Lines {
			l := &f.Hunks[hi].Lines[li]
			if l.Type == LineAdd || l.Type == LineRemove {
				l.Staged = newState
			}
		}
	}
	f.Touched = true
}

// applyCurrentFileStaging applies the current file's staging to git immediately.
func (s *AppState) applyCurrentFileStaging() {
	if s.FileIdx < 0 || s.FileIdx >= len(s.Files) {
		return
	}
	f := &s.Files[s.FileIdx]
	if !f.Touched {
		return
	}
	applyStagingForFile(f)
}

// toggleHunk toggles all stageable lines in the current hunk.
func (s *AppState) toggleHunk() {
	if s.LineIdx < 0 || s.LineIdx >= len(s.DisplayLines) {
		return
	}
	hunkIdx := s.DisplayLines[s.LineIdx].HunkIdx

	// Check if any stageable line in the hunk is unstaged
	anyUnstaged := false
	for _, dl := range s.DisplayLines {
		if dl.HunkIdx == hunkIdx && dl.Line != nil &&
			(dl.Line.Type == LineAdd || dl.Line.Type == LineRemove) {
			if !dl.Line.Staged {
				anyUnstaged = true
				break
			}
		}
	}

	// Set all to staged if any were unstaged, otherwise unstage all
	newState := anyUnstaged
	for _, dl := range s.DisplayLines {
		if dl.HunkIdx == hunkIdx && dl.Line != nil &&
			(dl.Line.Type == LineAdd || dl.Line.Type == LineRemove) {
			dl.Line.Staged = newState
		}
	}

	s.Files[s.FileIdx].Touched = true
}

// run is the main application loop.
func run() error {
	if !isGitRepo() {
		return fmt.Errorf("not a git repository")
	}

	// Change to repo root so all paths are consistent
	root, err := gitRoot()
	if err != nil {
		return err
	}
	if err := os.Chdir(root); err != nil {
		return fmt.Errorf("chdir to git root: %w", err)
	}

	files, err := discoverFiles()
	if err != nil {
		return err
	}

	// Load diffs for all files
	for i := range files {
		f := &files[i]
		switch f.Status {
		case StatusUntracked:
			hunks, err := synthesizeDiff(f.Path)
			if err != nil {
				continue
			}
			f.Hunks = hunks
		default:
			hunks, err := loadDiff(f.Path)
			if err != nil {
				continue
			}
			f.Hunks = hunks

			// Mark pre-existing staging
			cachedHunks, _ := loadCachedDiff(f.Path)
			if len(cachedHunks) > 0 {
				markPreStaged(f.Hunks, cachedHunks)
			}
		}
	}

	// Filter out files with no hunks
	var filtered []DiffFile
	for _, f := range files {
		if len(f.Hunks) > 0 {
			filtered = append(filtered, f)
		}
	}
	files = filtered

	if len(files) == 0 {
		fmt.Println("No changes to stage.")
		return nil
	}

	// Enter TUI mode
	if err := enableRawMode(); err != nil {
		return fmt.Errorf("enable raw mode: %w", err)
	}
	defer disableRawMode()

	enterAltScreen()
	defer exitAltScreen()

	w, h := getTerminalSize()
	state := &AppState{
		Files:   files,
		FileIdx: 0,
		Width:   w,
		Height:  h,
	}
	state.buildDisplayLines()
	state.LineIdx = state.firstStageableLine()
	state.adjustScroll()

	// Read keys in a goroutine so we can also handle resize
	keyCh := make(chan KeyAction, 1)
	go func() {
		for {
			k := readKey()
			keyCh <- k
		}
	}()

	// Poll for terminal size changes
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	render(state)

	for {
		select {
		case <-ticker.C:
			w, h := getTerminalSize()
			if w != state.Width || h != state.Height {
				state.Width = w
				state.Height = h
				state.adjustFileScroll()
				state.adjustScroll()
				render(state)
			}

		case key := <-keyCh:
			if key == KeyNone {
				continue
			}

			if state.PendingKey != KeyNone {
				pending := state.PendingKey
				state.PendingKey = KeyNone
				switch {
				case pending == KeyG && key == KeyG:
					if state.DiffFocused {
						state.diffFirst()
					} else {
						state.selectFile(0)
					}
				case pending == KeyRightBracket && key == KeyC:
					if state.DiffFocused {
						state.nextHunk()
					}
				case pending == KeyLeftBracket && key == KeyC:
					if state.DiffFocused {
						state.prevHunk()
					}
				case pending == KeyM && key == KeyC:
					state.toggleHunk()
					state.VisualMode = false
					state.applyCurrentFileStaging()
				case pending == KeyShiftM && key == KeyC:
					state.stageCurrentFile()
					state.VisualMode = false
					state.applyCurrentFileStaging()
				}
			} else {
				switch key {
				case KeyJ, KeyDown:
					if state.DiffFocused {
						state.moveDown()
					} else {
						state.selectFile(state.FileIdx + 1)
					}
				case KeyK, KeyUp:
					if state.DiffFocused {
						state.moveUp()
					} else {
						state.selectFile(state.FileIdx - 1)
					}
				case KeyShiftJ:
					if state.DiffFocused {
						state.moveDownN(5)
					} else {
						state.selectFile(state.FileIdx + 5)
					}
				case KeyShiftK:
					if state.DiffFocused {
						state.moveUpN(5)
					} else {
						state.selectFile(state.FileIdx - 5)
					}
				case KeyH, KeyLeft:
					state.DiffFocused = false
					state.VisualMode = false
				case KeyL, KeyRight:
					state.DiffFocused = true
				case KeyG, KeyLeftBracket, KeyRightBracket, KeyM, KeyShiftM:
					state.PendingKey = key
				case KeyShiftG:
					if state.DiffFocused {
						state.diffLast()
					} else {
						state.selectFile(len(state.Files) - 1)
					}
				case KeyTab:
					state.DiffFocused = !state.DiffFocused
					state.VisualMode = false
				case KeyV, KeyShiftV:
					if state.DiffFocused && !state.VisualMode {
						state.VisualMode = true
						state.VisualAnchor = state.LineIdx
					}
				case KeyS:
					if state.VisualMode {
						state.toggleVisualSelection()
					} else {
						state.toggleLine()
					}
					state.applyCurrentFileStaging()
				case KeyShiftS, KeyShiftTab:
					state.toggleHunk()
					state.VisualMode = false
					state.applyCurrentFileStaging()
				case KeyEnter:
					state.stageCurrentFile()
					state.VisualMode = false
					state.applyCurrentFileStaging()
				case KeyEsc:
					if state.VisualMode {
						state.VisualMode = false
					}
				case KeyQ, KeyCtrlC:
					return nil
				}
			}

			state.Width, state.Height = getTerminalSize()
			state.adjustFileScroll()
			state.adjustScroll()
			render(state)
		}
	}
}
