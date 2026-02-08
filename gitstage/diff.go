package main

import (
	"strconv"
	"strings"
)

// parseDiff parses unified diff output into hunks.
func parseDiff(raw string) []Hunk {
	lines := strings.Split(raw, "\n")
	var hunks []Hunk
	var current *Hunk
	inHeader := true

	for i, line := range lines {
		// Skip trailing empty line (artifact of split)
		if i == len(lines)-1 && line == "" {
			continue
		}

		// Check for new file boundary
		if strings.HasPrefix(line, "diff --git ") {
			if current != nil {
				hunks = append(hunks, *current)
				current = nil
			}
			inHeader = true
			continue
		}

		// Check for hunk header
		if strings.HasPrefix(line, "@@") {
			if current != nil {
				hunks = append(hunks, *current)
			}
			h := parseHunkHeader(line)
			current = &h
			inHeader = false
			continue
		}

		if inHeader {
			continue
		}

		if current == nil {
			continue
		}

		// Skip "no newline" marker
		if strings.HasPrefix(line, "\\ No newline") {
			continue
		}

		// Classify the line
		var dl DiffLine
		if strings.HasPrefix(line, "+") {
			dl = DiffLine{Content: line, Type: LineAdd}
		} else if strings.HasPrefix(line, "-") {
			dl = DiffLine{Content: line, Type: LineRemove}
		} else {
			dl = DiffLine{Content: line, Type: LineContext}
		}
		current.Lines = append(current.Lines, dl)
	}

	if current != nil {
		hunks = append(hunks, *current)
	}

	return hunks
}

// parseHunkHeader parses "@@ -A,B +C,D @@ optional text" into a Hunk (lines empty).
func parseHunkHeader(line string) Hunk {
	// Split on @@, take the middle part
	parts := strings.SplitN(line, "@@", 3)
	if len(parts) < 2 {
		return Hunk{}
	}
	middle := strings.TrimSpace(parts[1])
	tokens := strings.Fields(middle)

	h := Hunk{}
	for _, tok := range tokens {
		if strings.HasPrefix(tok, "-") {
			h.OrigStart, h.OrigCount = parseRange(tok[1:])
		} else if strings.HasPrefix(tok, "+") {
			h.NewStart, h.NewCount = parseRange(tok[1:])
		}
	}
	return h
}

// parseRange parses "A,B" or "A" into start and count. If no comma, count defaults to 1.
func parseRange(s string) (int, int) {
	parts := strings.SplitN(s, ",", 2)
	start, _ := strconv.Atoi(parts[0])
	count := 1
	if len(parts) == 2 {
		count, _ = strconv.Atoi(parts[1])
	}
	return start, count
}
