resource "tls_private_key" "github_ssh_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
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


resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

resource "kubernetes_secret" "ssh_keypair" {
  metadata {
    name      = "github-ssh-keypair"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    "identity.pub" =  tls_private_key.github_ssh_key.public_key_openssh
    "identity"     = tls_private_key.github_ssh_key.private_key_pem
    "known_hosts"  = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }

  depends_on = [kubernetes_namespace.flux_system]
}

resource "github_repository" "gitops" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "public"
  auto_init   = true
}

resource "github_repository_deploy_key" "gitops" {
  title      = "Flux"
  repository = github_repository.gitops.name
  key        = tls_private_key.github_ssh_key.public_key_openssh
  read_only  = "false"
}

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux_system]

  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
}

// Configure the Flux instance.
resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]
  
  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

  // Configure the Flux distribution.
  set {
    name  = "instance.distribution.version"
    value = "2.x"
  }
  set {
    name  = "instance.distribution.registry"
    value = "ghcr.io/fluxcd"
  }

  // Configure Flux Git sync.
  set {
    name  = "instance.sync.kind"
    value = "GitRepository"
  }
  set {
    name  = "instance.sync.url"
    value = "https://github.com/${var.github_org}/${var.github_repository}.git"
  }
  set {
    name  = "instance.sync.path"
    value = "/"
  }
  set {
    name  = "instance.sync.ref"
    value = "refs/heads/main"
  }
  set {
    name  = "instance.sync.pullSecret"
    value = "github-ssh-keypair"
  }
}

module "flux_tf_controller_runner_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix = "${module.eks.cluster_name}-flux-tf-controller-runner"

  role_policy_arns = {
    RunnerPolicy = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["flux-system:tf-runner"]
    }
  }

  depends_on = [
    kubernetes_namespace.flux_system
    ]  
}

resource "helm_release" "flux_tf_controller" {
  name       = "tf-controller"
  repository = "https://flux-iac.github.io/tofu-controller"
  chart      = "tf-controller"
  version    = var.flux_tf_controller_chart_version
  namespace  = "flux-system"

  set {
    name  = "runner.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.flux_tf_controller_runner_irsa.iam_role_arn
  }     

  depends_on = [
    helm_release.flux_instance,
    module.flux_tf_controller_runner_irsa
    ]
}