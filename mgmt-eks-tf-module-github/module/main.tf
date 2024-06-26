module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.11"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.ng_subnets
  control_plane_subnet_ids = var.eks_subnets
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }   

  eks_managed_node_groups = {
   NG1= {      
      name         = "${var.eks_cluster_name}-nodegroup"
      min_size     = var.node_instance_min_capacity
      max_size     = var.node_instance_max_capacity
      desired_size = var.node_instance_desired_capacity

      launch_template_name   = "${var.eks_cluster_name}-managed-tmpl"
      instance_types          = [var.node_instance_type]
      tags = {
        Terraform   = "true"
      }
   }
  }
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
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

  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }  

  tags = {
    Environment = "dev"
  }
}

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

resource "helm_release" "flux2" {
  name       = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = var.flux2_chart_version
  namespace  = "flux-system"

  depends_on = [
    kubernetes_namespace.flux_system,
    module.eks.module
    ]
}

resource "helm_release" "flux2_sync" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = var.flux2_sync_chart_version

  # Note: Do not change the name or namespace of gitops resource. The below mimics the behaviour of "flux bootstrap".
  name      = "flux-system"
  namespace = "flux-system"

  set {
    name  = "gitRepository.spec.url"
    value = github_repository.gitops.http_clone_url
  }

  set {
    name  = "gitRepository.spec.ref.branch"
    value = "main"
  }

  set {
    name  = "gitRepository.spec.secretRef.name"
    value = kubernetes_secret.ssh_keypair.metadata[0].name
  }

  set {
    name  = "gitRepository.spec.interval"
    value = "1m"
  }

  depends_on = [helm_release.flux2]
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
    helm_release.flux2,
    module.flux_tf_controller_runner_irsa
    ]
}

output "eks_kubeconfig" {
  value = <<-EOT
    aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region}
  EOT
}

output "github_repo_url" {
  value = github_repository.gitops.http_clone_url
}

output "github_credentials_secret_arn" {
  value = aws_secretsmanager_secret.github_credentials.arn
}