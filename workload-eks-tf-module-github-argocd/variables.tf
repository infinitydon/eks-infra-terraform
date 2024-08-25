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

variable "use_ubuntu_ami" {
  description = "Use Ubuntu based AMI or not"
  default = false
}

variable "create_external_dns" {
  description = "Flag to control the creation of the external DNS chart"
  type        = bool
}

variable "external_dns_domain_name" {
  description = "Route53 private hosted zone domain name"
}