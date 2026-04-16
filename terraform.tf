terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 6.40.0"
    }
    archive = {
        source  = "hashicorp/archive"
        version = "~> 2.7.1"
    }
  }
  required_version = "~> 1.14"

  cloud {
    organization = "leonardo-aws-cloud-resume"

    workspaces {
      name = "awscloudresume-GitHub-action"
    }
  }

}