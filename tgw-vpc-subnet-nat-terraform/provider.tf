terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"      
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }    
  }
}

provider "aws" {
  region = var.region
  ignore_tags {
     key_prefixes = ["kubernetes.io"]
  }
}

provider "github" {
  token = var.github_token
}