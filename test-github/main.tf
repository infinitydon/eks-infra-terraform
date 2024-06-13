terraform {
  required_providers {
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

provider "github" {
  token = var.github_token
}

resource "tls_private_key" "github_ssh_key" {
  for_each    = toset(var.github_repositories)
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}


resource "github_repository" "gitops" {
  for_each   = toset(var.github_repositories)
  name       = each.key
  description = each.key
  visibility = "public"
  auto_init  = true
}

resource "github_repository_deploy_key" "gitops" {
  for_each  = toset(var.github_repositories)
  title     = "Flux"
  repository = github_repository.gitops[each.key].name
  key       = tls_private_key.github_ssh_key[each.key].public_key_openssh
  read_only = false
}
