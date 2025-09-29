package github

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v3"
)

func TestCodeownerRule_YAML(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected CodeownerRule
	}{
		{
			name: "basic rule",
			input: `
path: "*.js"
owners:
  - "@frontend-team"
  - "@lead-developer"`,
			expected: CodeownerRule{
				Path:   "*.js",
				Owners: []string{"@frontend-team", "@lead-developer"},
			},
		},
		{
			name: "global rule",
			input: `
path: "*"
owners:
  - "@admin"`,
			expected: CodeownerRule{
				Path:   "*",
				Owners: []string{"@admin"},
			},
		},
		{
			name: "directory rule",
			input: `
path: "/docs/"
owners:
  - "@docs-team"`,
			expected: CodeownerRule{
				Path:   "/docs/",
				Owners: []string{"@docs-team"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var rule CodeownerRule
			err := yaml.Unmarshal([]byte(tt.input), &rule)
			assert.NoError(t, err)
			assert.Equal(t, tt.expected.Path, rule.Path)
			assert.Equal(t, tt.expected.Owners, rule.Owners)
		})
	}
}

func TestRepository_WithCodeowners(t *testing.T) {
	input := `
name: "test-repo"
description: "Test repository"
codeowners:
  - path: "*"
    owners:
      - "@team-leads"
  - path: "*.go"
    owners:
      - "@backend-team"
  - path: "/frontend/"
    owners:
      - "@frontend-team"`

	var repo Repository
	err := yaml.Unmarshal([]byte(input), &repo)
	assert.NoError(t, err)

	assert.Len(t, repo.Codeowners, 3)

	// Test first rule
	assert.Equal(t, "*", repo.Codeowners[0].Path)
	assert.Equal(t, []string{"@team-leads"}, repo.Codeowners[0].Owners)

	// Test second rule
	assert.Equal(t, "*.go", repo.Codeowners[1].Path)
	assert.Equal(t, []string{"@backend-team"}, repo.Codeowners[1].Owners)

	// Test third rule
	assert.Equal(t, "/frontend/", repo.Codeowners[2].Path)
	assert.Equal(t, []string{"@frontend-team"}, repo.Codeowners[2].Owners)
}

func TestRepository_EmptyCodeowners(t *testing.T) {
	input := `
name: "test-repo"
description: "Test repository"`

	var repo Repository
	err := yaml.Unmarshal([]byte(input), &repo)
	assert.NoError(t, err)

	assert.Len(t, repo.Codeowners, 0)
}