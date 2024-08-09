terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"      
    }
  }
}

provider "aws" {
  region = var.region
}

module "eks_mgmt" {
  source = "./module"

  eks_cluster_name    = var.eks_cluster_name
  eks_cluster_version = var.eks_cluster_version
  github_repository = var.github_repository
  github_org     = var.github_org
  github_token   = var.github_token
  node_instance_type = var.node_instance_type
  node_instance_min_capacity = var.node_instance_min_capacity
  node_instance_max_capacity = var.node_instance_max_capacity
  node_instance_desired_capacity = var.node_instance_desired_capacity
}

output "eks_kubeconfig" {
  value = module.eks_mgmt.eks_kubeconfig
}

output "github_repo_url" {
  value = module.eks_mgmt.github_repo_url
}

output "github_credentials_secret_arn" {
  value = module.eks_mgmt.github_credentials_secret_arn
}