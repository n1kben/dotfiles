package main

import (
	"testing"
)

func TestParseRange(t *testing.T) {
	tests := []struct {
		input     string
		wantStart int
		wantCount int
	}{
		{"1,5", 1, 5},
		{"1,7", 1, 7},
		{"0,0", 0, 0},
		{"10", 10, 1}, // missing count defaults to 1
		{"1,2", 1, 2},
	}
	for _, tt := range tests {
		start, count := parseRange(tt.input)
		if start != tt.wantStart || count != tt.wantCount {
			t.Errorf("parseRange(%q) = (%d, %d), want (%d, %d)",
				tt.input, start, count, tt.wantStart, tt.wantCount)
		}
	}
}

func TestParseHunkHeader(t *testing.T) {
	tests := []struct {
		input               string
		origStart, origCount int
		newStart, newCount   int
	}{
		{"@@ -1,5 +1,7 @@", 1, 5, 1, 7},
		{"@@ -1 +1,2 @@", 1, 1, 1, 2},
		{"@@ -0,0 +1,3 @@", 0, 0, 1, 3},
		{"@@ -10,6 +10,7 @@ func main()", 10, 6, 10, 7},
	}
	for _, tt := range tests {
		h := parseHunkHeader(tt.input)
		if h.OrigStart != tt.origStart || h.OrigCount != tt.origCount ||
			h.NewStart != tt.newStart || h.NewCount != tt.newCount {
			t.Errorf("parseHunkHeader(%q) = {%d,%d,%d,%d}, want {%d,%d,%d,%d}",
				tt.input,
				h.OrigStart, h.OrigCount, h.NewStart, h.NewCount,
				tt.origStart, tt.origCount, tt.newStart, tt.newCount)
		}
	}
}

func TestParseDiffSingleHunk(t *testing.T) {
	diff := `diff --git a/file.go b/file.go
index abc1234..def5678 100644
--- a/file.go
+++ b/file.go
@@ -10,6 +10,7 @@ package main
 context line
+new line added
-removed line
 another context
`

	hunks := parseDiff(diff)
	if len(hunks) != 1 {
		t.Fatalf("expected 1 hunk, got %d", len(hunks))
	}

	h := hunks[0]
	if h.OrigStart != 10 || h.OrigCount != 6 || h.NewStart != 10 || h.NewCount != 7 {
		t.Errorf("hunk header = {%d,%d,%d,%d}, want {10,6,10,7}",
			h.OrigStart, h.OrigCount, h.NewStart, h.NewCount)
	}

	if len(h.Lines) != 4 {
		t.Fatalf("expected 4 lines, got %d", len(h.Lines))
	}

	expected := []struct {
		typ     LineType
		content string
	}{
		{LineContext, " context line"},
		{LineAdd, "+new line added"},
		{LineRemove, "-removed line"},
		{LineContext, " another context"},
	}

	for i, exp := range expected {
		if h.Lines[i].Type != exp.typ {
			t.Errorf("line %d type = %d, want %d", i, h.Lines[i].Type, exp.typ)
		}
		if h.Lines[i].Content != exp.content {
			t.Errorf("line %d content = %q, want %q", i, h.Lines[i].Content, exp.content)
		}
	}
}

func TestParseDiffMultiHunk(t *testing.T) {
	diff := `diff --git a/file.go b/file.go
--- a/file.go
+++ b/file.go
@@ -1,3 +1,4 @@
 line1
+added1
 line2
@@ -10,3 +11,2 @@
 line10
-removed10
 line11
`
	hunks := parseDiff(diff)
	if len(hunks) != 2 {
		t.Fatalf("expected 2 hunks, got %d", len(hunks))
	}

	if len(hunks[0].Lines) != 3 {
		t.Errorf("hunk 0: expected 3 lines, got %d", len(hunks[0].Lines))
	}
	if len(hunks[1].Lines) != 3 {
		t.Errorf("hunk 1: expected 3 lines, got %d", len(hunks[1].Lines))
	}
}

func TestParseDiffNoNewlineMarker(t *testing.T) {
	diff := `diff --git a/file b/file
--- a/file
+++ b/file
@@ -1,2 +1,2 @@
-old
+new
\ No newline at end of file
`
	hunks := parseDiff(diff)
	if len(hunks) != 1 {
		t.Fatalf("expected 1 hunk, got %d", len(hunks))
	}
	if len(hunks[0].Lines) != 2 {
		t.Errorf("expected 2 lines (no newline marker skipped), got %d", len(hunks[0].Lines))
	}
}

func TestParseDiffTrailingEmptyLine(t *testing.T) {
	diff := "diff --git a/f b/f\n--- a/f\n+++ b/f\n@@ -1,1 +1,2 @@\n line1\n+line2\n"
	hunks := parseDiff(diff)
	if len(hunks) != 1 {
		t.Fatalf("expected 1 hunk, got %d", len(hunks))
	}
	if len(hunks[0].Lines) != 2 {
		t.Errorf("expected 2 lines, got %d", len(hunks[0].Lines))
	}
}
