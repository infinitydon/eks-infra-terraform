locals {
  ran = {
    region                          = var.workload_cluster_region
    vpc_id                          = module.vpc_ran.vpc_id
    eks_subnets                     = ["${module.vpc_ran.public_subnets[0]}","${module.vpc_ran.public_subnets[1]}","${module.vpc_ran.private_subnets[0]}", "${module.vpc_ran.private_subnets[1]}"]
    ng_subnets                      = ["${module.vpc_ran.private_subnets[0]}"]
    multus_security_group_id        = aws_security_group.ran_multus_sg.id
    multus_subnets                  = "${module.vpc_ran.private_subnets[2]},${module.vpc_ran.private_subnets[3]},${module.vpc_ran.private_subnets[4]},${module.vpc_ran.private_subnets[5]}"
    github_credentails_secret_name  = aws_secretsmanager_secret.github_credentials[var.github_repositories[0]].name
    attach_2nd_eni_lambda_s3_bucket = var.attach_2nd_eni_lambda_s3_bucket
    github_org                      = var.github_org
    github_repository               = var.github_repositories[0]
  }

  control_plane = {
    region                          = var.workload_cluster_region
    vpc_id                          = module.vpc_core_controlplane.vpc_id
    eks_subnets                     = ["${module.vpc_core_controlplane.public_subnets[0]}","${module.vpc_core_controlplane.public_subnets[1]}","${module.vpc_core_controlplane.private_subnets[0]}", "${module.vpc_core_controlplane.private_subnets[1]}"]
    ng_subnets                      = ["${module.vpc_core_controlplane.private_subnets[0]}"]
    multus_security_group_id        = aws_security_group.core_controlplane_multus_sg.id
    multus_subnets                  = "${module.vpc_core_controlplane.private_subnets[2]},${module.vpc_core_controlplane.private_subnets[3]}"
    github_credentails_secret_name  = aws_secretsmanager_secret.github_credentials[var.github_repositories[1]].name
    attach_2nd_eni_lambda_s3_bucket = var.attach_2nd_eni_lambda_s3_bucket
    github_org                      = var.github_org
    github_repository               = var.github_repositories[1]
    hosted_zone_arn                 = aws_route53_zone.controlplane_internal.arn
    hosted_zone_id                 = aws_route53_zone.controlplane_internal.id
  }  

  user_plane = {
    region                          = var.workload_cluster_region
    vpc_id                          = module.vpc_core_userplane.vpc_id
    eks_subnets                     = ["${module.vpc_core_userplane.public_subnets[0]}","${module.vpc_core_userplane.public_subnets[1]}","${module.vpc_core_userplane.private_subnets[0]}", "${module.vpc_core_userplane.private_subnets[1]}"]
    ng_subnets                      = ["${module.vpc_core_userplane.private_subnets[0]}"]
    multus_security_group_id        = aws_security_group.core_userplane_multus_sg.id
    multus_subnets                  = "${module.vpc_core_userplane.private_subnets[2]},${module.vpc_core_userplane.private_subnets[3]},${module.vpc_core_userplane.private_subnets[4]}"
    github_credentails_secret_name  = aws_secretsmanager_secret.github_credentials[var.github_repositories[2]].name
    attach_2nd_eni_lambda_s3_bucket = var.attach_2nd_eni_lambda_s3_bucket
    github_org                      = var.github_org
    github_repository               = var.github_repositories[2]
  }

  ran_json = jsonencode(local.ran)
  control_plane_json = jsonencode(local.control_plane)
  user_plane_json = jsonencode(local.user_plane)
}

resource "aws_ssm_parameter" "ran" {
  name  = "/${var.ran_parameter_store_name}/config"
  type  = "String"
  value = local.ran_json
}

resource "aws_ssm_parameter" "control_plane" {
  name  = "/${var.control_plane_parameter_store_name}/config"
  type  = "String"
  value = local.control_plane_json
}

resource "aws_ssm_parameter" "user_plane" {
  name  = "/${var.user_plane_parameter_store_name}/config"
  type  = "String"
  value = local.user_plane_json
}