package main

import (
	"testing"
)

func makeTestState() *AppState {
	files := []DiffFile{
		{
			Path:   "file1.go",
			Status: StatusModified,
			Hunks: []Hunk{
				{
					OrigStart: 1, OrigCount: 3, NewStart: 1, NewCount: 4,
					Lines: []DiffLine{
						{Content: " context", Type: LineContext},
						{Content: "+added1", Type: LineAdd},
						{Content: "-removed1", Type: LineRemove},
						{Content: " context2", Type: LineContext},
					},
				},
				{
					OrigStart: 20, OrigCount: 2, NewStart: 21, NewCount: 3,
					Lines: []DiffLine{
						{Content: " ctx", Type: LineContext},
						{Content: "+added2", Type: LineAdd},
					},
				},
			},
		},
		{
			Path:   "file2.txt",
			Status: StatusUntracked,
			Hunks: []Hunk{
				{
					OrigStart: 0, OrigCount: 0, NewStart: 1, NewCount: 2,
					Lines: []DiffLine{
						{Content: "+line1", Type: LineAdd},
						{Content: "+line2", Type: LineAdd},
					},
				},
			},
		},
	}

	state := &AppState{
		Files:  files,
		Width:  80,
		Height: 24,
	}
	state.buildDisplayLines()
	state.LineIdx = state.firstStageableLine()
	return state
}

func TestBuildDisplayLines(t *testing.T) {
	state := makeTestState()

	// File 1 has 2 hunks: hunk header + 4 lines, hunk header + 2 lines = 8 display lines
	if len(state.DisplayLines) != 8 {
		t.Fatalf("expected 8 display lines, got %d", len(state.DisplayLines))
	}

	// First line should be hunk header
	if !state.DisplayLines[0].IsHunkHeader {
		t.Error("first display line should be hunk header")
	}

	// Second line should be a diff line
	if state.DisplayLines[1].Line == nil {
		t.Error("second display line should have a Line pointer")
	}
	if state.DisplayLines[1].Line.Content != " context" {
		t.Errorf("second display line content = %q, want %q", state.DisplayLines[1].Line.Content, " context")
	}
}

func TestFirstStageableLine(t *testing.T) {
	state := makeTestState()

	// First stageable line should be the first add/remove, which is index 2
	// (index 0 = hunk header, index 1 = context line, index 2 = add line)
	idx := state.firstStageableLine()
	if idx != 2 {
		t.Errorf("firstStageableLine = %d, want 2", idx)
	}

	dl := state.DisplayLines[idx]
	if dl.Line == nil || dl.Line.Type != LineAdd {
		t.Errorf("expected add line at first stageable position")
	}
}

func TestMoveDown(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 1 // context line

	state.moveDown()
	if state.LineIdx != 2 { // should move to the add line
		t.Errorf("after moveDown, LineIdx = %d, want 2", state.LineIdx)
	}

	state.moveDown()
	if state.LineIdx != 3 { // remove line
		t.Errorf("after moveDown, LineIdx = %d, want 3", state.LineIdx)
	}
}

func TestMoveUp(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 3 // remove line

	state.moveUp()
	if state.LineIdx != 2 { // add line
		t.Errorf("after moveUp, LineIdx = %d, want 2", state.LineIdx)
	}

	state.moveUp()
	if state.LineIdx != 1 { // context line
		t.Errorf("after moveUp, LineIdx = %d, want 1", state.LineIdx)
	}
}

func TestMoveDownSkipsHunkHeaders(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 4 // last line of first hunk ("context2")

	state.moveDown()
	// Should skip the hunk header at index 5 and land on index 6 (context "ctx")
	if state.LineIdx != 6 {
		t.Errorf("after moveDown past hunk header, LineIdx = %d, want 6", state.LineIdx)
	}
}

func TestToggleLine(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 2 // add line

	if state.DisplayLines[2].Line.Staged {
		t.Error("line should start unstaged")
	}

	state.toggleLine()
	if !state.Files[0].Hunks[0].Lines[1].Staged {
		t.Error("line should be staged after toggle")
	}
	if !state.Files[0].Touched {
		t.Error("file should be marked as touched")
	}

	// Should auto-advance to next stageable line (the remove line at index 3)
	if state.LineIdx != 3 {
		t.Errorf("after toggle, LineIdx = %d, want 3 (auto-advance)", state.LineIdx)
	}
}

func TestToggleLineSkipsContext(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 1 // context line

	state.toggleLine()
	// Should do nothing - context lines can't be toggled
	if state.Files[0].Touched {
		t.Error("file should not be touched when toggling context")
	}
}

func TestToggleHunk(t *testing.T) {
	state := makeTestState()
	state.LineIdx = 2 // in hunk 0

	// All lines start unstaged, so toggle should stage all
	state.toggleHunk()
	for _, l := range state.Files[0].Hunks[0].Lines {
		if l.Type == LineAdd || l.Type == LineRemove {
			if !l.Staged {
				t.Errorf("line %q should be staged after hunk toggle", l.Content)
			}
		}
	}

	// Toggle again: all staged → unstage all
	state.toggleHunk()
	for _, l := range state.Files[0].Hunks[0].Lines {
		if l.Type == LineAdd || l.Type == LineRemove {
			if l.Staged {
				t.Errorf("line %q should be unstaged after second hunk toggle", l.Content)
			}
		}
	}
}

func TestNextFile(t *testing.T) {
	state := makeTestState()

	state.nextFile()
	if state.FileIdx != 1 {
		t.Errorf("FileIdx = %d, want 1", state.FileIdx)
	}

	// Display lines should now be for file2
	if len(state.DisplayLines) != 3 { // 1 hunk header + 2 lines
		t.Errorf("expected 3 display lines for file2, got %d", len(state.DisplayLines))
	}
}

func TestPrevFile(t *testing.T) {
	state := makeTestState()
	state.FileIdx = 1
	state.buildDisplayLines()

	state.prevFile()
	if state.FileIdx != 0 {
		t.Errorf("FileIdx = %d, want 0", state.FileIdx)
	}
}

func TestPreStaging(t *testing.T) {
	fullHunks := []Hunk{
		{
			Lines: []DiffLine{
				{Content: " context", Type: LineContext},
				{Content: "+added1", Type: LineAdd},
				{Content: "+added2", Type: LineAdd},
				{Content: "-removed1", Type: LineRemove},
			},
		},
	}

	cachedHunks := []Hunk{
		{
			Lines: []DiffLine{
				{Content: "+added1", Type: LineAdd},
				{Content: "-removed1", Type: LineRemove},
			},
		},
	}

	markPreStaged(fullHunks, cachedHunks)

	if !fullHunks[0].Lines[1].Staged {
		t.Error("+added1 should be pre-staged")
	}
	if fullHunks[0].Lines[2].Staged {
		t.Error("+added2 should NOT be pre-staged")
	}
	if !fullHunks[0].Lines[3].Staged {
		t.Error("-removed1 should be pre-staged")
	}
}
