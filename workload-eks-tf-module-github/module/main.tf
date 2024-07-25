data "aws_caller_identity" "current" {}

data "aws_ami" "eks_ubuntu" {
  count = var.use_ubuntu_ami ? 1 : 0
  most_recent = true
  owners = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${var.eks_cluster_version}/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
        name = "virtualization-type"
        values = ["hvm"]
  }
}


resource "aws_iam_role" "eks_admin_role" {
  name = "${var.eks_cluster_name}-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
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

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.11"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.ng_subnets
  control_plane_subnet_ids = var.eks_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = false
  enable_cluster_creator_admin_permissions = true
  create_kms_key                 = false
  cluster_encryption_config = {}

  cluster_addons = {
    coredns = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
      env = {
        AWS_VPC_K8S_CNI_EXTERNALSNAT = "true",
        AWS_VPC_K8S_CNI_EXCLUDE_SNAT_CIDRS = "10.0.0.0/8"
      }
      })
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      resolve_conflicts = "OVERWRITE"
    }
  }  

  access_entries = {
    # Add entry for Role that wants to administer the EKS cluster
    eks-access-infra = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.eks_admin_role.arn

      policy_associations = {
        eks-access-policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  self_managed_node_groups = {
   NG1= {      
      name         = "${var.eks_cluster_name}-nodegroup"
      ami_id       = var.use_ubuntu_ami ? element(data.aws_ami.eks_ubuntu.*.id, 0) : null
      min_size     = var.node_instance_min_capacity
      max_size     = var.node_instance_max_capacity
      desired_size = var.node_instance_desired_capacity
      vpc_security_group_ids = var.vpc_security_group_ids
      launch_template_name   = "${var.eks_cluster_name}-managed-tmpl"
      instance_type         = var.node_instance_type
      enable_bootstrap_user_data = true
      post_bootstrap_user_data = <<-EOT
        echo "net.ipv4.conf.default.rp_filter = 0" | tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.rp_filter = 0" | tee -a /etc/sysctl.conf
        sudo sysctl -p
        sleep 45
        ls /sys/class/net/ > /tmp/ethList;cat /tmp/ethList |while read line ; do sudo ifconfig $line up; done
        grep eth /tmp/ethList |while read line ; do echo "ifconfig $line up" >> /etc/rc.d/rc.local; done
        chmod +x /etc/rc.d/rc.local
        systemctl enable rc-local --now
        reboot
      EOT
      tags = {
        Terraform   = "true"
      }
   }
  }
}

resource "aws_security_group_rule" "allow_additional_cidrs" {
  count = length(var.additional_cidrs_to_allow) > 0 ? length(var.additional_cidrs_to_allow) : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = [element(var.additional_cidrs_to_allow, count.index)]
}

module "external_secret_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix = "${module.eks.cluster_name}-external-secret"

  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-secrets-sa"]
    }
  }
}

module "external_dns_irsa" {
  count = var.create_external_dns ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix = "${module.eks.cluster_name}-external-dns"

  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "kubernetes_service_account" "external-dns" {
    count = var.create_external_dns ? 1 : 0
    metadata {
        name      = "external-dns"
        namespace = "kube-system"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.external_dns_irsa[0].iam_role_arn
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

data "aws_secretsmanager_secret" "github_credentials" {
  name = var.git_credentials_secret
}

data "aws_secretsmanager_secret_version" "github_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.github_credentials.id
}

locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.github_credentials_version.secret_string)
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
    "identity.pub" =  local.secret_data.public_key
    "identity"     = local.secret_data.private_key
    "known_hosts"  = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }

  depends_on = [kubernetes_namespace.flux_system]
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
    value = "https://github.com/${var.github_org}/${var.github_repository}.git"
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

resource "helm_release" "external_dns" {
  count = var.create_external_dns ? 1 : 0
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_chart_version

  # Note: Do not change the name or namespace of gitops resource. The below mimics the behaviour of "flux bootstrap".
  name      = "external-dns"
  namespace = "kube-system"

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "domainFilters[0]"
    value = var.external_dns_domain_name
  }

  set {
    name  = "logLevel"
    value = "info"
  }

  set {
    name  = "txtOwnerId"
    value = var.eks_cluster_name
  }  

  depends_on = [module.external_dns_irsa]

}

output "eks_kubeconfig" {
  value = <<-EOT
    aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region} --role-arn ${aws_iam_role.eks_admin_role.arn}
  EOT
}