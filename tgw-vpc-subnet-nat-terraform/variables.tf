variable "region" {
  description = "Region"
  type        = string
  default     = "us-west-2"
}

variable "ran_az1" {
  description = "AZ 1"
  type        = string
  default     = "us-west-2a"
}

variable "ran_az2" {
  description = "AZ 2"
  type        = string
  default     = "us-west-2b"
}

variable "vpc_ran_cidr" {
  description = "The ID of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ran_eks_private_subnet_1" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.1.0/24"
}


variable "ran_eks_private_subnet_2" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ran_f1_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.3.0/24"
}

variable "ran_f1_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.0.3.16/28"
}

variable "ran_e1_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.4.0/24"
}

variable "ran_e1_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.0.4.16/28"
}

variable "ran_n2_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.5.0/24"
}

variable "ran_n2_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.0.5.16/28"
}

variable "ran_n3_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.6.0/24"
}

variable "ran_n3_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.0.6.16/28"
}

variable "ran_public_subnet_1" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.7.0/24"
}

variable "ran_public_subnet_2" {
  description = "The Subnet ID"
  type        = string
  default     = "10.0.8.0/24"
}

variable "core_controlplane_az1" {
  description = "AZ 1"
  type        = string
  default     = "us-west-2a"
}

variable "core_controlplane_az2" {
  description = "AZ 2"
  type        = string
  default     = "us-west-2b"
}

variable "vpc_core_controlplane_cidr" {
  description = "The ID of the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "core_controlplane_eks_private_subnet_1" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.1.0/24"
}

variable "core_controlplane_eks_private_subnet_2" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.2.0/24"
}

variable "core_controlplane_core_n2_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.3.0/24"
}

variable "core_controlplane_core_n2_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.1.3.16/28"
}

variable "core_controlplane_core_n4_private_subnet" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.4.0/24"
}

variable "core_controlplane_core_n4_private_subnet_cidr_reservation" {
  description = "The CIDR Subnet Reservation"
  type        = string
  default     = "10.1.4.16/28"
}

variable "core_controlplane_public_subnet_1" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.5.0/24"
}

variable "core_controlplane_public_subnet_2" {
  description = "The Subnet ID"
  type        = string
  default     = "10.1.6.0/24"
}

variable "core_userplane_az1" {
    description = "AZ 1"
    type        = string
    default     = "us-west-2a"
  }
  
  variable "core_userplane_az2" {
    description = "AZ 2"
    type        = string
    default     = "us-west-2b"
  }
  
  variable "vpc_core_userplane_cidr" {
    description = "The ID of the VPC"
    type        = string
    default     = "10.2.0.0/16"
  }
  
  variable "core_userplane_eks_private_subnet_1" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.1.0/24"
  }
  
  variable "core_userplane_eks_private_subnet_2" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.2.0/24"
  }
  
  variable "core_userplane_core_n3_private_subnet" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.3.0/24"
  }
  
  variable "core_userplane_core_n3_private_subnet_cidr_reservation" {
    description = "The CIDR Subnet Reservation"
    type        = string
    default     = "10.2.3.16/28"
  }
  
  variable "core_userplane_core_n4_private_subnet" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.4.0/24"
  }
  
  variable "core_userplane_core_n4_private_subnet_cidr_reservation" {
    description = "The CIDR Subnet Reservation"
    type        = string
    default     = "10.2.4.16/28"
  }

  variable "core_userplane_core_n6_private_subnet" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.5.0/24"
  }
  
  variable "core_userplane_core_n6_private_subnet_cidr_reservation" {
    description = "The CIDR Subnet Reservation"
    type        = string
    default     = "10.2.5.16/28"
  }  
  
  variable "core_userplane_public_subnet_1" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.6.0/24"
  }
  
  variable "core_userplane_public_subnet_2" {
    description = "The Subnet ID"
    type        = string
    default     = "10.2.7.0/24"
  }

variable "workload_cluster_region" {
  description = "The AWS region to deploy workload cluster resources in"
  type        = string
}

variable "ran_parameter_store_name" {
  description = "Name of the parameter store, ideally should be EKS clustername"
  default = "ran-5g"
}

variable "control_plane_parameter_store_name" {
  description = "Name of the parameter store, ideally should be EKS clustername"
  default = "control-plane-5g"
}

variable "user_plane_parameter_store_name" {
  description = "Name of the parameter store, ideally should be EKS clustername"
  default = "user-plane-5g"
}

variable "attach_2nd_eni_lambda_s3_bucket" {
  description = "Specify S3 Bucket(directory) where you locate Lambda function (Attach2ndENI function)"
  type        = string
}

variable "github_org" {
  description = "Github Org or Username"
  type = string
}

variable "github_repositories" {
  type    = list(string)
  default = ["telco-ran-5g", "telco-control-plane-5g", "telco-user-plane-5g"]  # List of repository names
}

variable "github_token" {
  description = "Github PAT"
  type = string
}