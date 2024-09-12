resource "tls_private_key" "github_ssh_key" {
  algorithm   = "RSA"
  rsa_bits  = "4096"
}

resource "aws_secretsmanager_secret" "github_credentials" {
  name_prefix = "${var.eks_cluster_name}"
}

resource "aws_secretsmanager_secret_version" "github_credentials_version" {
  secret_id = aws_secretsmanager_secret.github_credentials.id
  secret_string = jsonencode({
    private_key = tls_private_key.github_ssh_key.private_key_pem
    public_key  = tls_private_key.github_ssh_key.public_key_openssh
  })
}

resource "github_repository" "gitops" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "public"
  auto_init   = true
}

resource "github_repository_deploy_key" "gitops" {
  title      = "ArgoCD"
  repository = github_repository.gitops.name
  key        = tls_private_key.github_ssh_key.public_key_openssh
  read_only  = "false"
}

resource "time_sleep" "wait_eks_access_seconds" {
  depends_on = [module.eks]

  create_duration = "60s"
}

resource "kubernetes_secret" "mgmt_repo_ssh_key" {
  depends_on = [module.eks_blueprints_addons, resource.time_sleep.wait_eks_access_seconds]
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
    sshPrivateKey = tls_private_key.github_ssh_key.private_key_pem
  }
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update gitops to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn  

  enable_aws_cloudwatch_metrics = true
  enable_aws_for_fluentbit = true
  aws_for_fluentbit = {
    enable_containerinsights = true
  }

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
    values        = [templatefile("${path.module}/argocd-values.yaml", {})]
  }

  tags = {
    Environment = "dev"
  }
}

# Extract the OIDC provider URL from the EKS module
locals {
  oidc_provider_url = module.eks.oidc_provider
  oidc_provider_id  = element(split("/", local.oidc_provider_url), length(split("/", local.oidc_provider_url)) - 1)
}

# IAM Role
resource "aws_iam_role" "terraform_runner" {
  name = "${module.eks.cluster_name}-terraform-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${local.oidc_provider_url}:aud": "sts.amazonaws.com",
            "${local.oidc_provider_url}:sub": "system:serviceaccount:tf-system:tf-*"
          }
        }
      }
    ]
  })
}

# IAM Policy attachment
resource "aws_iam_role_policy_attachment" "attach_runner_policy" {
  role       = aws_iam_role.terraform_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "helm_release" "terraform_operator" {
  depends_on = [time_sleep.wait_eks_access_seconds]
  name       = "terraform-operator"
  repository = "https://galleybytes.github.io/helm-charts"
  chart      = "terraform-operator"
  version    = var.terraform_operator_version

  namespace = "tf-system"

  create_namespace = true
}

resource "helm_release" "argocd_default_app" {
  depends_on = [module.eks_blueprints_addons]
  name       = "nephio-app"
  chart      = "oci://ghcr.io/infinitydon/nephio-app"
  version    = var.argocd_default_app_version
  namespace = "argocd"
  set {
    name  = "githubOrg"
    value = var.github_org
  }
  set {
    name  = "githubRepo"
    value = var.github_repository
  }    
}