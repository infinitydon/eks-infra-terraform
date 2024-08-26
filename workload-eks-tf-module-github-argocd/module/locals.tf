locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.github_credentials_version.secret_string)
  transformed_eks_version = tonumber(replace(var.eks_cluster_version, "\"", ""))
}