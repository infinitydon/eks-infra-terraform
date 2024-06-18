variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "eks_cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.25"
}

variable "vpc_id" {
  description = "The VPC ID to deploy resources in"
  type        = string
}

variable "eks_subnets" {
  description = "A list of subnet IDs to deploy resources in"
  type        = list(string)
}

variable "ng_subnets" {
  description = "A list of subnet IDs to deploy resources in"
  type        = list(string)
}

variable "node_instance_type" {
  description = "The instance type for the EKS nodes"
  type        = string
  default     = "t3.medium"
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
  description = "Github Org or Username"
  type = string
}

variable "git_credentials_secret" {
  description = "AWS secret manager name that has the github SSH credentials"
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

variable "multus_subnets" {
  description = "Subnets To Use In Creating Secondary ENIs"
  type        = string
}

variable "source_dest_check_enable" {
  description = "Enable or Disable src-dst checking"
  type        = bool
  default     = true
}

variable "use_ips_from_start_of_subnet" {
  description = "False -> use DHCP allocation (use it when using subnet CIDR reservation), True -> Allocate IPs from begining of the subnet(Lambda does this handling)"
  type        = bool
  default =  true
}

variable "interface_tags" {
  description = "(Optional) Any additional tags to be applied on the multus intf (Key value pair, separated by comma ex: cnf=abc01,type=5g)"
  type        = string
  default = ""
}

variable "attach_2nd_eni_lambda_s3_bucket" {
  description = "Specify S3 Bucket(directory) where you locate Lambda function (Attach2ndENI function)"
  type        = string
}

variable "attach_2nd_eni_lambda_s3_key" {
  description = "Specify S3 Key(filename) of your Lambda Function (Attach2ndENI)"
  type        = string
  default = "lambda_function.zip"
}

variable "multus_security_group_id" {
  description = "The security group ID for the Multus interfaces"
  type        = string
}

variable "flux2_chart_version" {
  default = "2.13.0"
}

variable "flux2_sync_chart_version" {
  default = "1.8.2"
}

variable "create_external_dns" {
  description = "Flag to control the creation of the external DNS chart"
  type        = bool
}

variable "external_dns_chart_version" {
  default = "1.14.5"
}

variable "external_dns_domain_name" {
  description = "Route53 private hosted zone domain name"
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "additional_cidrs_to_allow" {
  description = "CIDRs to allow in the NodeGroup security"
  type        = list(string)
  default = []
}