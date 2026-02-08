package main

import (
	"fmt"
	"os"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "gitstage: %v\n", err)
		os.Exit(1)
	}
}
