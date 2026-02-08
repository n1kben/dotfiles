package main

import (
	"testing"
)

func TestVisibleLen(t *testing.T) {
	tests := []struct {
		input string
		want  int
	}{
		{"hello", 5},
		{"\x1b[32mhello\x1b[0m", 5},
		{"\x1b[48;5;22mgreen bg\x1b[0m", 8},
		{"", 0},
		{"\x1b[31m\x1b[0m", 0},
		{"abc\x1b[2mdef\x1b[0m", 6},
	}
	for _, tt := range tests {
		got := visibleLen(tt.input)
		if got != tt.want {
			t.Errorf("visibleLen(%q) = %d, want %d", tt.input, got, tt.want)
		}
	}
}

func TestTruncateVisible(t *testing.T) {
	tests := []struct {
		input string
		max   int
		want  int // expected visible length after truncation
	}{
		{"hello", 3, 3},
		{"hello", 10, 5},
		{"\x1b[32mhello world\x1b[0m", 5, 5},
		{"abc", 0, 0},
		{"", 5, 0},
	}
	for _, tt := range tests {
		result := truncateVisible(tt.input, tt.max)
		got := visibleLen(result)
		if got != tt.want {
			t.Errorf("truncateVisible(%q, %d) visible len = %d, want %d (result=%q)",
				tt.input, tt.max, got, tt.want, result)
		}
	}
}

func TestVisibleLenUTF8(t *testing.T) {
	// UTF-8 multi-byte characters
	tests := []struct {
		input string
		want  int
	}{
		{"▸", 1},
		{"✓", 1},
		{"…path/to/file", 13},
	}
	for _, tt := range tests {
		got := visibleLen(tt.input)
		if got != tt.want {
			t.Errorf("visibleLen(%q) = %d, want %d", tt.input, got, tt.want)
		}
	}
}
