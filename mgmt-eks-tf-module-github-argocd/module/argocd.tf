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
        name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
      },
      {
        name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
        value = "internet-facing" # or "internal" based on your use case
      }
    ]
  }

  tags = {
    Environment = "dev"
  }
}

module "terranetes_controller_runner_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix = "${module.eks.cluster_name}-terranetes-executor"

  role_policy_arns = {
    RunnerPolicy = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["terraform-system:terraform-executor"]
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "terranetes_controller" {
  depends_on = [time_sleep.wait_eks_access_seconds]
  name       = "terranetes-controller"
  repository = "https://terranetes-controller.appvia.io"
  chart      = "terranetes-controller"
  version    = var.terranetes_version

  namespace = "terraform-system"

  create_namespace = true

  set {
    name  = "rbac.executor.create"
    value = true
  }

  set {
    name  = "rbac.executor.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.flux_tf_controller_runner_irsa.iam_role_arn
  }
}