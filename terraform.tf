# Terraform configuration file for AWS provider

terraform {
  /*cloud {
    organization = "<your organization name>"
    workspaces {
      name = "<your workspace name>"
    }
}*/

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.2.0"
}