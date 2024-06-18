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

data "aws_ssm_parameter" "workload" {
  name = "/${var.parameter_store_name}/config"
}

locals {
  workload_config = jsondecode(data.aws_ssm_parameter.workload.value)
}

module "workload_cluster" {
  source = "./module"

  eks_cluster_name    = var.eks_cluster_name
  eks_cluster_version = var.eks_cluster_version
  vpc_id          = local.workload_config.vpc_id
  ng_subnets      = local.workload_config.ng_subnets
  eks_subnets = local.workload_config.eks_subnets
  github_repository = local.workload_config.github_repository
  git_credentials_secret = local.workload_config.github_credentails_secret_name
  github_org   = local.workload_config.github_org
  multus_subnets  = local.workload_config.multus_subnets
  multus_security_group_id  = local.workload_config.multus_security_group_id
  attach_2nd_eni_lambda_s3_bucket = local.workload_config.attach_2nd_eni_lambda_s3_bucket
  node_instance_type = var.node_instance_type
  node_instance_min_capacity = var.node_instance_min_capacity
  node_instance_max_capacity = var.node_instance_max_capacity
  node_instance_desired_capacity = var.node_instance_desired_capacity
  create_external_dns  = local.workload_config.create_external_dns
  external_dns_chart_version = var.external_dns_chart_version
  external_dns_domain_name  = local.workload_config.external_dns_domain_name
  additional_cidrs_to_allow = var.additional_cidrs_to_allow
}

output "eks_kubeconfig" {
  value = module.workload_cluster.eks_kubeconfig
}