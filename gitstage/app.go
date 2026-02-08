package main

import (
	"fmt"
	"os"
)

// AppState holds the full application state.
type AppState struct {
	Files        []DiffFile
	FileIdx      int
	LineIdx      int
	ScrollOffset int
	DisplayLines []DisplayLine
	Width        int
	Height       int
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

// adjustScroll ensures the cursor is visible within the right pane.
func (s *AppState) adjustScroll() {
	contentHeight := s.Height - 2
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

// nextFile selects the next file.
func (s *AppState) nextFile() {
	if s.FileIdx < len(s.Files)-1 {
		s.FileIdx++
		s.buildDisplayLines()
		s.ScrollOffset = 0
		s.LineIdx = s.firstStageableLine()
		s.adjustScroll()
	}
}

// prevFile selects the previous file.
func (s *AppState) prevFile() {
	if s.FileIdx > 0 {
		s.FileIdx--
		s.buildDisplayLines()
		s.ScrollOffset = 0
		s.LineIdx = s.firstStageableLine()
		s.adjustScroll()
	}
}

// toggleLine toggles the staged state of the current line, then auto-advances.
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

	// Auto-advance to next stageable line
	for i := s.LineIdx + 1; i < len(s.DisplayLines); i++ {
		d := &s.DisplayLines[i]
		if d.Line != nil && (d.Line.Type == LineAdd || d.Line.Type == LineRemove) {
			s.LineIdx = i
			s.adjustScroll()
			return
		}
	}
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

	// Handle resize signals
	resizeCh := make(chan os.Signal, 1)
	listenForResize(resizeCh)

	render(state)

	for {
		// Check for resize (non-blocking)
		select {
		case <-resizeCh:
			state.Width, state.Height = getTerminalSize()
			state.adjustScroll()
			render(state)
			continue
		default:
		}

		key := readKey()
		switch key {
		case KeyNone:
			continue
		case KeyJ:
			state.moveDown()
		case KeyK:
			state.moveUp()
		case KeyCtrlJ:
			state.nextFile()
		case KeyCtrlK:
			state.prevFile()
		case KeyTab:
			state.toggleLine()
		case KeyShiftTab:
			state.toggleHunk()
		case KeyEnter:
			// Save and exit
			disableRawMode()
			exitAltScreen()
			if err := applyStaging(state.Files); err != nil {
				return fmt.Errorf("apply staging: %w", err)
			}
			return nil
		case KeyEsc, KeyQ:
			// Abort
			return nil
		}

		render(state)
	}
}
