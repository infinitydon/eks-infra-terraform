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

variable "node_instance_desired_capacity" {
  default = "1"
}

variable "node_instance_max_capacity" {
  default = "2"
}

variable "node_instance_min_capacity" {
  default = "1"
}

variable "parameter_store_name" {
  description = "Parameter for the workload-cluster, this is where vpc-id, subnets, multus details etc will be picked up"
}

variable "external_dns_chart_version" {
  default = "1.14.5"
}

variable "additional_cidrs_to_allow" {
  description = "CIDRs to allow in the NodeGroup security"
  type        = list(string)
  default = [ "10.0.0.0/8" ]
}

variable "argocd_version" {
  default = "7.4.5"
}

variable "argocd_default_app_version" {
  default = "0.1.0"
}

variable "free5gc_kernel" {
  type    = string
  default = "disable"
  description = "Enable Free5GC kernel module installation (yes/no)"
}