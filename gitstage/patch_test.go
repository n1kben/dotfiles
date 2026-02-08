package main

import (
	"strings"
	"testing"
)

func TestGeneratePatchAllStaged(t *testing.T) {
	f := &DiffFile{
		Path:   "test.go",
		Status: StatusModified,
		Hunks: []Hunk{
			{
				OrigStart: 1, OrigCount: 3, NewStart: 1, NewCount: 4,
				Lines: []DiffLine{
					{Content: " context", Type: LineContext},
					{Content: "+added", Type: LineAdd, Staged: true},
					{Content: "-removed", Type: LineRemove, Staged: true},
					{Content: " context2", Type: LineContext},
				},
			},
		},
	}

	patch := generatePatch(f)

	if !strings.Contains(patch, "diff --git a/test.go b/test.go") {
		t.Error("missing patch header")
	}
	if !strings.Contains(patch, "--- a/test.go") {
		t.Error("missing --- header")
	}
	if !strings.Contains(patch, "+++ b/test.go") {
		t.Error("missing +++ header")
	}
	if !strings.Contains(patch, "+added") {
		t.Error("missing added line")
	}
	if !strings.Contains(patch, "-removed") {
		t.Error("missing removed line")
	}

	// Check counts: context=2(orig+new), add=1(new), remove=1(orig) → orig=3, new=3
	if !strings.Contains(patch, "@@ -1,3 +1,3 @@") {
		t.Errorf("wrong hunk header in patch: %s", patch)
	}
}

func TestGeneratePatchPartialStaging(t *testing.T) {
	f := &DiffFile{
		Path:   "test.go",
		Status: StatusModified,
		Hunks: []Hunk{
			{
				OrigStart: 1, OrigCount: 4, NewStart: 1, NewCount: 5,
				Lines: []DiffLine{
					{Content: " context", Type: LineContext},
					{Content: "+added1", Type: LineAdd, Staged: true},
					{Content: "+added2", Type: LineAdd, Staged: false},
					{Content: "-removed1", Type: LineRemove, Staged: true},
					{Content: "-removed2", Type: LineRemove, Staged: false},
					{Content: " context2", Type: LineContext},
				},
			},
		},
	}

	patch := generatePatch(f)

	// Staged add stays as add
	if !strings.Contains(patch, "+added1") {
		t.Error("missing staged add line")
	}
	// Unstaged add dropped entirely
	if strings.Contains(patch, "added2") {
		t.Error("unstaged add should be dropped")
	}
	// Staged remove stays as remove
	if !strings.Contains(patch, "-removed1") {
		t.Error("missing staged remove line")
	}
	// Unstaged remove becomes context (space prefix)
	if !strings.Contains(patch, " removed2") {
		t.Error("unstaged remove should become context")
	}

	// Counts: context=2(each +1,+1), add1 staged(+1 new), remove1 staged(+1 orig), remove2 unstaged→context(+1,+1)
	// orig = 2(context) + 1(remove staged) + 1(remove unstaged→context) = 4
	// new = 2(context) + 1(add staged) + 1(remove unstaged→context) = 4
	if !strings.Contains(patch, "@@ -1,4 +1,4 @@") {
		t.Errorf("wrong hunk header, got: %s", patch)
	}
}

func TestGeneratePatchNothingStaged(t *testing.T) {
	f := &DiffFile{
		Path:   "test.go",
		Status: StatusModified,
		Hunks: []Hunk{
			{
				OrigStart: 1, OrigCount: 2, NewStart: 1, NewCount: 3,
				Lines: []DiffLine{
					{Content: " context", Type: LineContext},
					{Content: "+added", Type: LineAdd, Staged: false},
				},
			},
		},
	}

	patch := generatePatch(f)
	if patch != "" {
		t.Errorf("expected empty patch, got: %s", patch)
	}
}

func TestGeneratePatchUntracked(t *testing.T) {
	f := &DiffFile{
		Path:   "newfile.txt",
		Status: StatusUntracked,
		Hunks: []Hunk{
			{
				OrigStart: 0, OrigCount: 0, NewStart: 1, NewCount: 3,
				Lines: []DiffLine{
					{Content: "+line1", Type: LineAdd, Staged: true},
					{Content: "+line2", Type: LineAdd, Staged: true},
					{Content: "+line3", Type: LineAdd, Staged: false},
				},
			},
		},
	}

	patch := generatePatch(f)

	if !strings.Contains(patch, "new file mode 100644") {
		t.Error("missing new file mode header")
	}
	if !strings.Contains(patch, "--- /dev/null") {
		t.Error("missing /dev/null for untracked file")
	}
	if !strings.Contains(patch, "+line1") {
		t.Error("missing staged line1")
	}
	if !strings.Contains(patch, "+line2") {
		t.Error("missing staged line2")
	}
	if strings.Contains(patch, "line3") {
		t.Error("unstaged line3 should be dropped")
	}

	// orig=0, new=2 (two staged adds)
	if !strings.Contains(patch, "@@ -0,0 +1,2 @@") {
		t.Errorf("wrong hunk header: %s", patch)
	}
}

func TestGeneratePatchLineCountCorrectness(t *testing.T) {
	f := &DiffFile{
		Path:   "test.go",
		Status: StatusModified,
		Hunks: []Hunk{
			{
				OrigStart: 5, OrigCount: 4, NewStart: 5, NewCount: 6,
				Lines: []DiffLine{
					{Content: " ctx1", Type: LineContext},
					{Content: "+add1", Type: LineAdd, Staged: true},
					{Content: "+add2", Type: LineAdd, Staged: true},
					{Content: "-rem1", Type: LineRemove, Staged: false},
					{Content: " ctx2", Type: LineContext},
					{Content: "+add3", Type: LineAdd, Staged: false},
				},
			},
		},
	}

	patch := generatePatch(f)

	// ctx1: orig+1, new+1 → (1,1)
	// +add1 staged: new+1 → (1,2)
	// +add2 staged: new+1 → (1,3)
	// -rem1 unstaged→context: orig+1,new+1 → (2,4)
	// ctx2: orig+1,new+1 → (3,5)
	// +add3 unstaged: dropped → (3,5)
	if !strings.Contains(patch, "@@ -5,3 +5,5 @@") {
		t.Errorf("wrong hunk header: %s", patch)
	}
}

func TestStageableCounts(t *testing.T) {
	f := &DiffFile{
		Hunks: []Hunk{
			{
				Lines: []DiffLine{
					{Content: " ctx", Type: LineContext},
					{Content: "+add1", Type: LineAdd, Staged: true},
					{Content: "+add2", Type: LineAdd, Staged: false},
				},
			},
			{
				Lines: []DiffLine{
					{Content: "-rem1", Type: LineRemove, Staged: true},
					{Content: "-rem2", Type: LineRemove, Staged: true},
				},
			},
		},
	}

	staged, total := countStaged(f)
	if staged != 3 {
		t.Errorf("staged = %d, want 3", staged)
	}
	if total != 4 {
		t.Errorf("total = %d, want 4", total)
	}
}
