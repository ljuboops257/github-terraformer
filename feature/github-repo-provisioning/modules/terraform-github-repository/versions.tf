# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM AND PROVIDER REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 1.0"

  required_providers {
    github = {
      # FIXME: Required until they mode to public repository
      source  = "github.com/G-Research/github"
      version = "6.5.0-gr"
    }
  }
}
