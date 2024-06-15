output "ran_vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc_ran.vpc_id
}

output "ran_eks_public_subnet_1" {
  description = "EKS Public subnet1 in AZ1"
  value       = module.vpc_ran.public_subnets[0]
}

output "ran_eks_public_subnet_2" {
  description = "EKS Public subnet2 in AZ2"
  value       = module.vpc_ran.public_subnets[1]
}

output "ran_eks_private_subnet_1" {
  description = "EKS Private subnet1 in AZ1"
  value       = module.vpc_ran.private_subnets[0]
}

output "ran_eks_private_subnet_2" {
  description = "EKS Private subnet2 in AZ2"
  value       = module.vpc_ran.private_subnets[1]
}

output "ran_f1_private_subnet" {
  description = "F1 Private subnet in AZ1"
  value       = module.vpc_ran.private_subnets[2]
}

output "ran_e1_private_subnet" {
  description = "E1 Private subnet in AZ1"
  value       = module.vpc_ran.private_subnets[3]
}

output "ran_n2_private_subnet" {
  description = "N2 Private subnet in AZ1"
  value       = module.vpc_ran.private_subnets[4]
}

output "ran_n3_private_subnet" {
  description = "N3 Private subnet in AZ1"
  value       = module.vpc_ran.private_subnets[5]
}



output "control_plane_vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc_core_controlplane.vpc_id
}

output "control_plane_eks_public_subnet_1" {
  description = "EKS Public subnet1 in AZ1"
  value       = module.vpc_core_controlplane.public_subnets[0]
}

output "control_plane_eks_public_subnet_2" {
  description = "EKS Public subnet2 in AZ2"
  value       = module.vpc_core_controlplane.public_subnets[1]
}

output "control_plane_eks_private_subnet_1" {
  description = "EKS Private subnet1 in AZ1"
  value       = module.vpc_core_controlplane.private_subnets[0]
}

output "control_plane_eks_private_subnet_2" {
  description = "EKS Private subnet2 in AZ2"
  value       = module.vpc_core_controlplane.private_subnets[1]
}

output "control_plane_core_n2_private_subnet" {
  description = "N2 Private subnet in AZ1"
  value       = module.vpc_core_controlplane.private_subnets[2]
}

output "control_plane_core_n4_private_subnet" {
    description = "N4 Private subnet in AZ1"
    value       = module.vpc_core_controlplane.private_subnets[3]
  }



output "user_plane_vpc_id" {
    description = "The ID of the VPC"
    value       = module.vpc_core_userplane.vpc_id
  }
  
  output "user_plane_eks_public_subnet_1" {
    description = "EKS Public subnet1 in AZ1"
    value       = module.vpc_core_userplane.public_subnets[0]
  }
  
  output "user_plane_eks_public_subnet_2" {
    description = "EKS Public subnet2 in AZ2"
    value       = module.vpc_core_userplane.public_subnets[1]
  }
  
  output "user_plane_eks_private_subnet_1" {
    description = "EKS Private subnet1 in AZ1"
    value       = module.vpc_core_userplane.private_subnets[0]
  }
  
  output "user_plane_eks_private_subnet_2" {
    description = "EKS Private subnet2 in AZ2"
    value       = module.vpc_core_userplane.private_subnets[1]
  }
  
  output "user_plane_core_n3_private_subnet" {
    description = "N3 Private subnet in AZ1"
    value       = module.vpc_core_userplane.private_subnets[2]
  }
  
  output "user_plane_core_n4_private_subnet" {
      description = "N4 Private subnet in AZ1"
      value       = module.vpc_core_userplane.private_subnets[3]
    }

  output "user_plane_core_n6_private_subnet" {
      description = "N6 Private subnet in AZ1"
      value       = module.vpc_core_userplane.private_subnets[4]
    }  

output "ran_multus_sg" {
    description = "Security Group To Allow Inbound Controlplane and Userplane Traffic"
    value       = aws_security_group.ran_multus_sg.id
  }

output "control_plane_multus_sg" {
    description = "Security Group To Allow Inbound RAN and Userplane Traffic"
    value       = aws_security_group.core_controlplane_multus_sg.id
  }

output "user_plane_multus_sg" {
    description = "Security Group To Allow Inbound RAN and Controlplane Traffic"
    value       = aws_security_group.core_userplane_multus_sg.id
  }

output "github_credentials_arns" {
  value = { for k, v in aws_secretsmanager_secret.github_credentials : k => v.arn }
}  

output "repository_https_urls" {
  value = { for repo in github_repository.gitops : repo.name => repo.html_url }
}

output "control_plane_hosted_zone_arn" {
  value = aws_route53_zone.controlplane_internal.arn
}