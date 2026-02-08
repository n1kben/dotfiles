package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// isGitRepo checks if we're inside a git repository.
func isGitRepo() bool {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	cmd.Stderr = nil
	return cmd.Run() == nil
}

// hasHead returns true if the repo has at least one commit.
func hasHead() bool {
	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Stderr = nil
	return cmd.Run() == nil
}

// discoverFiles runs git status --porcelain and returns classified files.
func discoverFiles() ([]DiffFile, error) {
	cmd := exec.Command("git", "status", "--porcelain")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git status: %w", err)
	}

	seen := make(map[string]bool)
	var files []DiffFile

	for _, line := range strings.Split(string(out), "\n") {
		if len(line) < 3 {
			continue
		}
		x := line[0]
		y := line[1]
		path := line[3:]

		if seen[path] {
			continue
		}
		seen[path] = true

		var status FileStatus
		switch {
		case x == '?' && y == '?':
			status = StatusUntracked
		case y == 'D' || x == 'D':
			status = StatusDeleted
		case y == 'M' || x == 'M' || x == 'A':
			status = StatusModified
		default:
			continue
		}

		files = append(files, DiffFile{
			Path:   path,
			Status: status,
		})
	}

	return files, nil
}

// loadDiff loads diff hunks for a tracked file.
func loadDiff(path string) ([]Hunk, error) {
	// Try full diff (staged + unstaged) against HEAD
	var hunks []Hunk
	if hasHead() {
		out, _ := gitCommand("diff", "HEAD", "--", path)
		if len(out) > 0 {
			hunks = parseDiff(out)
		}
	}

	// If empty, try cached only
	if len(hunks) == 0 {
		out, _ := gitCommand("diff", "--cached", "--", path)
		if len(out) > 0 {
			hunks = parseDiff(out)
		}
	}

	return hunks, nil
}

// loadCachedDiff loads only the staged changes for a file.
func loadCachedDiff(path string) ([]Hunk, error) {
	out, _ := gitCommand("diff", "--cached", "--", path)
	if len(out) == 0 {
		return nil, nil
	}
	return parseDiff(out), nil
}

// markPreStaged marks lines in fullHunks that are already staged based on cachedHunks.
func markPreStaged(fullHunks []Hunk, cachedHunks []Hunk) {
	// Build a multiset of (content, type) from cached hunks
	type lineKey struct {
		content string
		typ     LineType
	}
	multiset := make(map[lineKey]int)
	for _, h := range cachedHunks {
		for _, l := range h.Lines {
			if l.Type == LineAdd || l.Type == LineRemove {
				multiset[lineKey{l.Content, l.Type}]++
			}
		}
	}

	// Walk full diff and mark matches
	for hi := range fullHunks {
		for li := range fullHunks[hi].Lines {
			l := &fullHunks[hi].Lines[li]
			if l.Type == LineAdd || l.Type == LineRemove {
				key := lineKey{l.Content, l.Type}
				if multiset[key] > 0 {
					l.Staged = true
					multiset[key]--
				}
			}
		}
	}
}

// synthesizeDiff creates a synthetic diff for an untracked file.
func synthesizeDiff(path string) ([]Hunk, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}

	lines := strings.Split(string(data), "\n")
	// Remove trailing empty line from split artifact
	if len(lines) > 0 && lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}

	if len(lines) == 0 {
		return nil, nil
	}

	hunk := Hunk{
		OrigStart: 0,
		OrigCount: 0,
		NewStart:  1,
		NewCount:  len(lines),
	}

	for _, l := range lines {
		hunk.Lines = append(hunk.Lines, DiffLine{
			Content: "+" + l,
			Type:    LineAdd,
			Staged:  false,
		})
	}

	return []Hunk{hunk}, nil
}

// gitCommand runs a git command and returns its stdout.
func gitCommand(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	out, err := cmd.Output()
	return string(out), err
}

// gitReset resets the index for a specific file.
func gitReset(path string) error {
	if !hasHead() {
		// No HEAD, use rm --cached instead
		cmd := exec.Command("git", "rm", "--cached", "--", path)
		cmd.Stderr = nil
		cmd.Run() // ignore errors (file might not be in index)
		return nil
	}
	cmd := exec.Command("git", "reset", "HEAD", "--", path)
	cmd.Stderr = nil
	return cmd.Run()
}

// gitAdd stages a file completely.
func gitAdd(path string) error {
	cmd := exec.Command("git", "add", "--", path)
	return cmd.Run()
}

// gitAddIntent marks an untracked file as "intent to add".
func gitAddIntent(path string) error {
	cmd := exec.Command("git", "add", "-N", "--", path)
	return cmd.Run()
}

// gitApplyCached applies a patch to the index via stdin.
func gitApplyCached(patch string) error {
	// Try with --allow-empty first
	cmd := exec.Command("git", "apply", "--cached", "--allow-empty", "-")
	cmd.Stdin = bytes.NewReader([]byte(patch))
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err == nil {
		return nil
	}

	// Retry without --allow-empty for older git
	cmd = exec.Command("git", "apply", "--cached", "-")
	cmd.Stdin = bytes.NewReader([]byte(patch))
	cmd.Stderr = &stderr
	return cmd.Run()
}

// applyStaging applies the user's staging selections for all touched files.
func applyStaging(files []DiffFile) error {
	for i := range files {
		f := &files[i]
		if !f.Touched {
			continue
		}

		stagedCount, totalCount := countStaged(f)

		if f.Status == StatusUntracked {
			if err := applyUntracked(f, stagedCount, totalCount); err != nil {
				return fmt.Errorf("apply untracked %s: %w", f.Path, err)
			}
		} else {
			if err := applyTracked(f, stagedCount, totalCount); err != nil {
				return fmt.Errorf("apply tracked %s: %w", f.Path, err)
			}
		}
	}
	return nil
}

func countStaged(f *DiffFile) (staged, total int) {
	for _, h := range f.Hunks {
		for _, l := range h.Lines {
			if l.Type == LineAdd || l.Type == LineRemove {
				total++
				if l.Staged {
					staged++
				}
			}
		}
	}
	return
}

func applyTracked(f *DiffFile, stagedCount, totalCount int) error {
	if err := gitReset(f.Path); err != nil {
		return err
	}
	if stagedCount == 0 {
		return nil
	}
	if stagedCount == totalCount {
		return gitAdd(f.Path)
	}
	patch := generatePatch(f)
	if patch == "" {
		return nil
	}
	return gitApplyCached(patch)
}

func applyUntracked(f *DiffFile, stagedCount, totalCount int) error {
	if stagedCount == 0 {
		return nil
	}
	if err := gitAddIntent(f.Path); err != nil {
		return err
	}
	if stagedCount == totalCount {
		return gitAdd(f.Path)
	}
	patch := generatePatch(f)
	if patch == "" {
		return nil
	}
	return gitApplyCached(patch)
}
