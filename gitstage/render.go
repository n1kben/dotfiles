package main

import (
	"bytes"
	"fmt"
	"os"
	"strings"
)

const (
	colorReset   = "\x1b[0m"
	colorGreen   = "\x1b[32m"
	colorRed     = "\x1b[31m"
	colorYellow  = "\x1b[33m"
	colorCyan    = "\x1b[36m"
	colorDim     = "\x1b[2m"
	colorReverse = "\x1b[7m"
	bgDarkGreen  = "\x1b[48;5;22m"
	bgDarkRed    = "\x1b[48;5;52m"
)

// render draws the entire screen.
func render(state *AppState) {
	var buf bytes.Buffer

	// Hide cursor and move to top-left
	buf.WriteString("\x1b[?25l")
	buf.WriteString("\x1b[H")
	// Clear screen
	buf.WriteString("\x1b[2J")

	w := state.Width
	h := state.Height

	if w < 40 || h < 10 {
		buf.WriteString("Terminal too small")
		buf.WriteString("\x1b[?25h")
		os.Stdout.Write(buf.Bytes())
		return
	}

	leftWidth := w * 30 / 100
	if leftWidth < 25 {
		leftWidth = 25
	}
	if leftWidth > 50 {
		leftWidth = 50
	}
	rightWidth := w - leftWidth - 1 // 1 for separator
	contentHeight := h - 2          // top border + bottom status bar

	// Row 1: top border
	buf.WriteString(colorDim)
	buf.WriteString("\u250c")
	buf.WriteString(strings.Repeat("\u2500", leftWidth))
	buf.WriteString("\u252c")
	buf.WriteString(strings.Repeat("\u2500", rightWidth))
	buf.WriteString("\u2510")
	buf.WriteString(colorReset)
	buf.WriteString("\r\n")

	// Content rows
	for row := 0; row < contentHeight; row++ {
		// Left pane
		buf.WriteString(colorDim)
		buf.WriteString("\u2502")
		buf.WriteString(colorReset)

		leftContent := renderFileListRow(state, row, leftWidth)
		buf.WriteString(leftContent)

		// Separator
		buf.WriteString(colorDim)
		buf.WriteString("\u2502")
		buf.WriteString(colorReset)

		// Right pane
		rightContent := renderDiffRow(state, row, rightWidth)
		buf.WriteString(rightContent)

		buf.WriteString(colorDim)
		buf.WriteString("\u2502")
		buf.WriteString(colorReset)
		buf.WriteString("\r\n")
	}

	// Bottom border
	buf.WriteString(colorDim)
	buf.WriteString("\u2514")
	buf.WriteString(strings.Repeat("\u2500", leftWidth))
	buf.WriteString("\u2534")
	buf.WriteString(strings.Repeat("\u2500", rightWidth))
	buf.WriteString("\u2518")
	buf.WriteString(colorReset)
	buf.WriteString("\r\n")

	// Status bar
	statusBar := " j/k:lines  C-j/C-k:files  Tab:toggle line  S-Tab:toggle hunk  Enter:save  Esc/q:abort"
	buf.WriteString(colorDim)
	buf.WriteString(truncateVisible(statusBar, w))
	buf.WriteString(colorReset)

	// Show cursor
	buf.WriteString("\x1b[?25h")

	os.Stdout.Write(buf.Bytes())
}

// renderFileListRow renders one row of the left pane.
func renderFileListRow(state *AppState, row, width int) string {
	if row >= len(state.Files) {
		return padRight("", width)
	}

	f := &state.Files[row]
	isSelected := row == state.FileIdx

	// Status char
	var statusChar string
	var statusColor string
	switch f.Status {
	case StatusModified:
		statusChar = "M"
		statusColor = colorYellow
	case StatusDeleted:
		statusChar = "D"
		statusColor = colorRed
	case StatusUntracked:
		statusChar = "?"
		statusColor = colorGreen
	}

	// Count staged/total
	staged, total := countStaged(f)
	counter := fmt.Sprintf("[%d/%d]", staged, total)
	var counterColor string
	switch {
	case staged == total && total > 0:
		counterColor = colorGreen
	case staged > 0:
		counterColor = colorYellow
	default:
		counterColor = colorDim
	}

	// Build the visible content:  "M path  [3/12]"
	// We need: 1 space + statusChar + 1 space + path + padding + counter + 1 space
	counterVisLen := len(counter)
	pathMaxLen := width - 3 - counterVisLen - 1 // " M " prefix + counter + trailing space
	if pathMaxLen < 1 {
		pathMaxLen = 1
	}

	displayPath := f.Path
	if len(displayPath) > pathMaxLen {
		displayPath = "\u2026" + displayPath[len(displayPath)-pathMaxLen+1:]
	}

	// Gap between path and counter
	gap := width - 3 - len(displayPath) - counterVisLen - 1
	if gap < 1 {
		gap = 1
	}

	var sb strings.Builder
	if isSelected {
		sb.WriteString(colorReverse)
	}
	sb.WriteString(" ")
	sb.WriteString(statusColor)
	sb.WriteString(statusChar)
	sb.WriteString(colorReset)
	if isSelected {
		sb.WriteString(colorReverse)
	}
	sb.WriteString(" ")
	sb.WriteString(displayPath)
	sb.WriteString(strings.Repeat(" ", gap))
	sb.WriteString(counterColor)
	sb.WriteString(counter)
	sb.WriteString(colorReset)
	if isSelected {
		sb.WriteString(colorReverse)
	}
	sb.WriteString(" ")
	sb.WriteString(colorReset)

	// Pad to exact width considering visible chars only
	visLen := 3 + len(displayPath) + gap + counterVisLen + 1
	if visLen < width {
		sb.WriteString(strings.Repeat(" ", width-visLen))
	}
	if isSelected {
		sb.WriteString(colorReset)
	}

	return sb.String()
}

// renderDiffRow renders one row of the right pane.
func renderDiffRow(state *AppState, row, width int) string {
	lineIdx := state.ScrollOffset + row
	if lineIdx >= len(state.DisplayLines) {
		return padRight("", width)
	}

	dl := &state.DisplayLines[lineIdx]
	isCurrent := lineIdx == state.LineIdx

	var sb strings.Builder

	// Gutter (3 chars)
	gutterWidth := 3
	if isCurrent {
		sb.WriteString(colorReverse)
		sb.WriteString(" \u25b8 ")
	} else {
		sb.WriteString("   ")
	}

	contentWidth := width - gutterWidth

	if dl.IsHunkHeader {
		text := truncateVisible(dl.HunkHeaderText, contentWidth)
		if isCurrent {
			sb.WriteString(colorCyan)
			sb.WriteString(text)
		} else {
			sb.WriteString(colorCyan)
			sb.WriteString(text)
		}
		visPad := contentWidth - visibleLen(dl.HunkHeaderText)
		if visPad > 0 {
			sb.WriteString(strings.Repeat(" ", visPad))
		}
		sb.WriteString(colorReset)
		return sb.String()
	}

	if dl.Line == nil {
		sb.WriteString(padRight("", contentWidth))
		sb.WriteString(colorReset)
		return sb.String()
	}

	line := dl.Line
	suffix := ""
	if line.Staged && (line.Type == LineAdd || line.Type == LineRemove) {
		suffix = " \u2713"
	}

	displayText := line.Content + suffix
	// Reserve width for display, truncate if needed
	truncated := truncateVisible(displayText, contentWidth)
	visLen := visibleLen(displayText)
	if visLen > contentWidth {
		visLen = contentWidth
	}

	switch line.Type {
	case LineAdd:
		if line.Staged {
			sb.WriteString(bgDarkGreen)
		}
		sb.WriteString(colorGreen)
	case LineRemove:
		if line.Staged {
			sb.WriteString(bgDarkRed)
		}
		sb.WriteString(colorRed)
	case LineContext:
		sb.WriteString(colorDim)
	}

	sb.WriteString(truncated)
	pad := contentWidth - visLen
	if pad > 0 {
		sb.WriteString(strings.Repeat(" ", pad))
	}
	sb.WriteString(colorReset)

	return sb.String()
}

// padRight pads a string with spaces to the given visible width.
func padRight(s string, width int) string {
	vl := visibleLen(s)
	if vl >= width {
		return s
	}
	return s + strings.Repeat(" ", width-vl)
}

// visibleLen returns the number of visible characters, excluding ANSI escape sequences.
func visibleLen(s string) int {
	count := 0
	inEsc := false
	for i := 0; i < len(s); i++ {
		if s[i] == 0x1b {
			inEsc = true
			continue
		}
		if inEsc {
			if (s[i] >= 'a' && s[i] <= 'z') || (s[i] >= 'A' && s[i] <= 'Z') {
				inEsc = false
			}
			continue
		}
		// Count UTF-8 start bytes
		b := s[i]
		if b < 0x80 || b >= 0xC0 {
			count++
		}
	}
	return count
}

// truncateVisible truncates a string to maxVisible visible characters, preserving ANSI sequences.
func truncateVisible(s string, maxVisible int) string {
	if maxVisible <= 0 {
		return ""
	}
	var sb strings.Builder
	count := 0
	inEsc := false
	for i := 0; i < len(s); i++ {
		if s[i] == 0x1b {
			inEsc = true
			sb.WriteByte(s[i])
			continue
		}
		if inEsc {
			sb.WriteByte(s[i])
			if (s[i] >= 'a' && s[i] <= 'z') || (s[i] >= 'A' && s[i] <= 'Z') {
				inEsc = false
			}
			continue
		}
		// Count UTF-8 start bytes as visible characters
		b := s[i]
		if b < 0x80 || b >= 0xC0 {
			if count >= maxVisible {
				sb.WriteString(colorReset)
				return sb.String()
			}
			count++
		}
		sb.WriteByte(s[i])
	}
	return sb.String()
}
