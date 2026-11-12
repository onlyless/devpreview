package main

import (
	"fmt"
	"strings"
)

type PreviewItem struct {
	Name       string
	Language   string
	Extensions []string
}

func (p PreviewItem) Summary() string {
	return fmt.Sprintf("%s (%s): %s", p.Name, p.Language, strings.Join(p.Extensions, ", "))
}

func main() {
	item := PreviewItem{
		Name:       "DevPreview",
		Language:   "Go",
		Extensions: []string{"go", "md", "json"},
	}
	fmt.Println(item.Summary())
}
