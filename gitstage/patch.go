package main

import (
	"fmt"
	"strings"
)

// generatePatch produces a unified diff patch for a file containing only staged lines.
func generatePatch(f *DiffFile) string {
	var patchHunks []string

	for _, h := range f.Hunks {
		hunkPatch := generateHunkPatch(h)
		if hunkPatch != "" {
			patchHunks = append(patchHunks, hunkPatch)
		}
	}

	if len(patchHunks) == 0 {
		return ""
	}

	var sb strings.Builder

	// Patch header
	sb.WriteString(fmt.Sprintf("diff --git a/%s b/%s\n", f.Path, f.Path))
	if f.Status == StatusUntracked {
		sb.WriteString("new file mode 100644\n")
		sb.WriteString("--- /dev/null\n")
	} else {
		sb.WriteString(fmt.Sprintf("--- a/%s\n", f.Path))
	}
	sb.WriteString(fmt.Sprintf("+++ b/%s\n", f.Path))

	for _, hp := range patchHunks {
		sb.WriteString(hp)
	}

	return sb.String()
}

// generateHunkPatch generates the patch text for a single hunk, including only staged changes.
func generateHunkPatch(h Hunk) string {
	// Check if any stageable line is staged
	hasStaged := false
	for _, l := range h.Lines {
		if (l.Type == LineAdd || l.Type == LineRemove) && l.Staged {
			hasStaged = true
			break
		}
	}
	if !hasStaged {
		return ""
	}

	var lines []string
	origCount := 0
	newCount := 0

	for _, l := range h.Lines {
		switch l.Type {
		case LineContext:
			lines = append(lines, l.Content)
			origCount++
			newCount++
		case LineAdd:
			if l.Staged {
				lines = append(lines, l.Content)
				newCount++
			}
			// Unstaged add: dropped entirely
		case LineRemove:
			if l.Staged {
				lines = append(lines, l.Content)
				origCount++
			} else {
				// Unstaged remove becomes context: replace '-' prefix with ' '
				lines = append(lines, " "+l.Content[1:])
				origCount++
				newCount++
			}
		}
	}

	if len(lines) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("@@ -%d,%d +%d,%d @@\n", h.OrigStart, origCount, h.NewStart, newCount))
	for _, l := range lines {
		sb.WriteString(l)
		sb.WriteString("\n")
	}

	return sb.String()
}
