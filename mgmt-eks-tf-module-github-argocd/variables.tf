variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "node_instance_type" {
  description = "The instance type for the EKS nodes"
  type        = string
}

variable "aws_load_balancer_controller_enable" {
  description = "Enable or disable AWS LB controller"
  type = bool
  default = true
}

variable "github_repository" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_token" {
  description = "Github PAT"
  type = string
}

variable "node_instance_desired_capacity" {
  default = "1"
}

variable "node_instance_max_capacity" {
  default = "1"
}

variable "node_instance_min_capacity" {
  default = "1"
}

variable "argocd_version" {
  default = "7.4.5"
}

variable "terraform_operator_version" {
  default = "0.7.2"
}

variable "argocd_default_app_version" {
  default = "0.1.0"
}