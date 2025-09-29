module "example_repository" {
  source = "./feature/github-repo-provisioning/modules/terraform-github-repository"

  name        = "example-repo"
  description = "Example repository with CODEOWNERS"
  visibility  = "private"

  # CODEOWNERS configuration
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
    },
    {
      path   = "/terraform/"
      owners = ["@example-org/devops-team"]
    },
    {
      path   = "*.tf"
      owners = ["@example-org/devops-team"]
    }
  ]

  # Other repository settings
  has_issues   = true
  has_wiki     = true
  topics       = ["example", "terraform", "codeowners"]

  admin_collaborators = ["admin-user"]
  push_teams         = ["example-org/developers"]

  # Optional: Override commit author/email for CODEOWNERS file
  # If not provided, uses the authenticated GitHub app information
  # codeowners_commit_author = "Custom Bot"
  # codeowners_commit_email  = "custom-bot@example.com"

  # Auto-bypass configuration (default: true)
  # Automatically adds the GitHub app as a bypasser to branch protections
  # and rulesets to ensure CODEOWNERS commits can be made
  auto_add_app_bypass = true

  # GitHub app slug (required for data source)
  github_app_slug = "your-app-slug"
}