data "aws_secretsmanager_secret" "github_credentials" {
  name = var.git_credentials_secret
}

data "aws_secretsmanager_secret_version" "github_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.github_credentials.id
}

locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.github_credentials_version.secret_string)
}

module "eks_blueprints_addons" {
  depends_on = [time_sleep.wait_eks_access_seconds]
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update gitops to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn  

  enable_aws_load_balancer_controller  = var.aws_load_balancer_controller_enable
  enable_argocd = true

  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  argocd = {
    name          = "argocd"
    chart_version = var.argocd_version
    repository    = "https://argoproj.github.io/argo-helm"
    namespace     = "argocd"
    set           = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      },
      {
        name  = "configs.cm.timeout.reconciliation"
        value = "60s"
      },
      {
        name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
      },
      {
        name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
        value = "internet-facing"
      }
    ]
  }

  tags = {
    Environment = "dev"
  }
}

resource "kubernetes_secret" "mgmt_repo_ssh_key" {
  depends_on = [module.eks_blueprints_addons]
  metadata {
    name      = "mgmt-repo-ssh-key"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type = "git"
    url  = "git@github.com:${var.github_org}"
    sshPrivateKey = local.secret_data.private_key
  }
}

resource "helm_release" "argocd_default_app" {
  depends_on = [module.eks_blueprints_addons]
  name       = "nephio-app"
  chart      = "oci://ghcr.io/infinitydon/nephio-app"
  version    = var.argocd_default_app_version
  namespace = "tf-system"
  set {
    name  = "githubOrg"
    value = var.github_org
  }
  set {
    name  = "githubRepo"
    value = var.github_repository
  }    
}