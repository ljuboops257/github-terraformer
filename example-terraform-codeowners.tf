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
}