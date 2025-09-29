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

### Variables

```hcl
variable "codeowners" {
  description = "(Optional) A list of CODEOWNERS rules for the repository."
  type = list(object({
    path   = string
    owners = list(string)
  }))
  default = []
}

variable "codeowners_commit_author" {
  description = "(Optional) The commit author for CODEOWNERS file. If not provided, uses the authenticated GitHub app name."
  type        = string
  default     = null
}

variable "codeowners_commit_email" {
  description = "(Optional) The commit email for CODEOWNERS file. If not provided, uses the authenticated GitHub app email format."
  type        = string
  default     = null
}

variable "auto_add_app_bypass" {
  description = "(Optional) Automatically add the current GitHub app as a bypasser to branch protections and rulesets."
  type        = bool
  default     = true
}

variable "github_app_slug" {
  description = "(Optional) The GitHub app slug for data source lookup."
  type        = string
  default     = null
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

1. **New Variables**: Added `codeowners`, `codeowners_commit_author`, and `codeowners_commit_email` variables in `variables.tf`
2. **GitHub App Data Source**: Added `data "github_app" "current"` to get authenticated app information
3. **Resource**: Added `github_repository_file` resource to create the CODEOWNERS file
4. **Content Generation**: Local value to generate CODEOWNERS file content
5. **Commit Attribution**: Uses authenticated GitHub app name and email with optional override
6. **Dependencies**: Proper dependency management with repository and branch creation

### Main Module Integration

Added `codeowners = try(each.value.codeowners, [])` to the module call in the main configuration to pass CODEOWNERS data from YAML to the module.

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

## Commit Attribution

The CODEOWNERS file commits are attributed using the authenticated GitHub app information:

- **Default Behavior**: Uses `data.github_app.current.name` as commit author and generates an appropriate email
- **Email Format**: `{app-slug}+{app-id}@users.noreply.github.com` following GitHub's conventions for app-generated commits
- **Override Options**: Use `codeowners_commit_author` and `codeowners_commit_email` variables to customize

Example with custom attribution:
```hcl
module "repository" {
  # ... other configuration ...

  codeowners_commit_author = "DevOps Bot"
  codeowners_commit_email  = "devops-bot@company.com"
}
```

## Limitations

1. The implementation creates a single CODEOWNERS file - existing files will be overwritten
2. The file is placed specifically in `.github/CODEOWNERS` (not at repository root)
3. The branch used is the default branch of the repository
4. Manual edits to the CODEOWNERS file will be overwritten on next Terraform apply
5. Requires GitHub App authentication to access app information for commit attribution

## Auto-Bypass Feature

When `auto_add_app_bypass = true` (default), the current GitHub app is automatically added as a bypasser to:

- **Branch Protections**: Added to `force_push_bypassers` and `pull_request_bypassers`
- **Repository Rulesets**: Added as a bypass actor with `bypass_mode = "always"`

This ensures the app can commit CODEOWNERS files even when strict branch protection rules or rulesets are in place.

### Configuration Requirements

1. **Main Module**: Add `app_slug` variable to your main module configuration
2. **Module Call**: The app slug is automatically passed to the repository module
3. **Data Sources**: Both main and repository modules use `data "github_app"` resources

### Example Usage

```hcl
# In your terraform.tfvars or variable definitions
app_slug = "your-github-app-slug"

# The module automatically handles the rest
module "repository" {
  source = "./modules/terraform-github-repository"

  # CODEOWNERS configuration
  codeowners = [...]

  # Auto-bypass is enabled by default
  auto_add_app_bypass = true  # Optional: can be set to false to disable
}
```