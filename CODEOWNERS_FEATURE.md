# CODEOWNERS Support in github-terraformer

This document describes the CODEOWNERS support implementation in the github-terraformer project.

## Overview

The github-terraformer now supports creating CODEOWNERS files for GitHub repositories through both the YAML configuration (github-repo-importer) and the Terraform module (github-repo-provisioning).

## Features

- **YAML Configuration**: Define CODEOWNERS rules in the repository YAML configuration
- **Terraform Module**: Create CODEOWNERS files directly through Terraform
- **Flexible Patterns**: Support for file patterns, directory patterns, and global rules
- **Multiple Owners**: Support for teams, users, and mixed ownership
- **Automatic File Placement**: CODEOWNERS file is automatically placed in `.github/CODEOWNERS`

## YAML Configuration (github-repo-importer)

### Schema

```yaml
repositories:
  owner/repo-name:
    codeowners:
      - path: "pattern"
        owners:
          - "@team-or-user"
          - "@another-owner"
```

### Examples

```yaml
repositories:
  example-org/my-repo:
    description: "Example repository with CODEOWNERS"
    visibility: "private"
    codeowners:
      # Global rule - all files
      - path: "*"
        owners:
          - "@example-org/team-leads"
          - "@admin-user"

      # JavaScript files
      - path: "*.js"
        owners:
          - "@example-org/frontend-team"

      # Go files
      - path: "*.go"
        owners:
          - "@example-org/backend-team"

      # Documentation directory
      - path: "/docs/"
        owners:
          - "@example-org/docs-team"
          - "@technical-writer"

      # Terraform files and directory
      - path: "/terraform/"
        owners:
          - "@example-org/devops-team"
      - path: "*.tf"
        owners:
          - "@example-org/devops-team"
```

## Terraform Module (github-repo-provisioning)

### Variable

```hcl
variable "codeowners" {
  description = "(Optional) A list of CODEOWNERS rules for the repository."
  type = list(object({
    path   = string
    owners = list(string)
  }))
  default = []
}
```

### Examples

```hcl
module "example_repository" {
  source = "./modules/terraform-github-repository"

  name        = "example-repo"
  description = "Example repository with CODEOWNERS"
  visibility  = "private"

  codeowners = [
    {
      path   = "*"
      owners = ["@example-org/team-leads", "@admin-user"]
    },
    {
      path   = "*.js"
      owners = ["@example-org/frontend-team"]
    },
    {
      path   = "*.go"
      owners = ["@example-org/backend-team"]
    },
    {
      path   = "/docs/"
      owners = ["@example-org/docs-team", "@technical-writer"]
    }
  ]

  # Other repository settings...
}
```

## Generated CODEOWNERS File

The implementation generates a CODEOWNERS file in the `.github/` directory with the following format:

```
* @example-org/team-leads @admin-user
*.js @example-org/frontend-team
*.go @example-org/backend-team
/docs/ @example-org/docs-team @technical-writer
/terraform/ @example-org/devops-team
*.tf @example-org/devops-team
```

## Path Patterns

The CODEOWNERS feature supports GitHub's standard path patterns:

- `*` - Global rule (all files)
- `*.ext` - Files with specific extension
- `/path/` - Specific directory
- `/path/**` - Directory and all subdirectories
- `path/file.ext` - Specific file

## Owner Formats

- `@username` - Individual user
- `@org/team-name` - Organization team
- `user@example.com` - Email address

## Implementation Details

### Go Library Changes

1. **New Struct**: Added `CodeownerRule` struct in `repositories.go`
2. **Repository Field**: Added `Codeowners []CodeownerRule` field to `Repository` struct
3. **YAML Tags**: Proper YAML marshaling/unmarshaling support

### Terraform Module Changes

1. **New Variable**: Added `codeowners` variable in `variables.tf`
2. **Resource**: Added `github_repository_file` resource to create the CODEOWNERS file
3. **Content Generation**: Local value to generate CODEOWNERS file content
4. **Dependencies**: Proper dependency management with repository and branch creation

### File Placement

The CODEOWNERS file is created in `.github/CODEOWNERS` which is the recommended location for GitHub to recognize it automatically.

## Testing

The implementation includes comprehensive tests:

- YAML parsing tests for `CodeownerRule` struct
- Repository configuration tests with CODEOWNERS
- Empty CODEOWNERS handling tests

Run tests with:
```bash
cd feature/github-repo-importer
go test ./pkg/github -v -run TestCodeowner
```

## Migration

For existing repositories:
1. The CODEOWNERS file will be created on the next Terraform apply
2. If a CODEOWNERS file already exists, it will be overwritten
3. The `overwrite_on_create = true` setting ensures the managed file takes precedence

## Limitations

1. The implementation creates a single CODEOWNERS file - existing files will be overwritten
2. The file is placed specifically in `.github/CODEOWNERS` (not at repository root)
3. The branch used is the default branch of the repository
4. Manual edits to the CODEOWNERS file will be overwritten on next Terraform apply