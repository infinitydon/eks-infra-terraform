data "aws_caller_identity" "current" {}

data "aws_ami" "eks_ubuntu" {
  count = var.use_ubuntu_ami ? 1 : 0
  most_recent = true
  owners = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${local.transformed_eks_version}/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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
  cluster_version = local.transformed_eks_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.ng_subnets
  control_plane_subnet_ids = var.eks_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = false
  enable_cluster_creator_admin_permissions = true
  create_kms_key                 = false
  cluster_encryption_config = {}

  cluster_addons = {
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
        # Apply sysctl settings
        echo "net.ipv4.conf.default.rp_filter=0" | tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.rp_filter=0" | tee -a /etc/sysctl.conf

        # Create the network configuration script
        cat << 'EOF' > /usr/local/bin/network-config.sh
        #!/bin/bash

        ls /sys/class/net/ > /tmp/ethList
        egrep "eth|ens" /tmp/ethList | while read line; do
            ip link set dev $line up
        done
        EOF

        chmod +x /usr/local/bin/network-config.sh

        # Create the systemd service file
        cat << 'EOF' > /etc/systemd/system/network-config.service
        [Unit]
        Description=Network Configuration Script
        After=network.target

        [Service]
        ExecStart=/usr/local/bin/network-config.sh
        RemainAfterExit=yes

        [Install]
        WantedBy=multi-user.target
        EOF

        # Reload systemd and enable the service
        systemctl daemon-reload
        systemctl enable network-config.service
        systemctl start network-config.service       

        # Reboot the system
        reboot
      EOT
      tags = {
        Terraform   = "true"
      }
   }
  }
}

resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ebs_csi_driver_irsa.iam_role_arn
  }

  depends_on = [module.eks]
}

resource "kubectl_manifest" "gp2_csi_storage_class" {
  depends_on = [helm_release.aws_ebs_csi_driver]

  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
YAML
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

resource "time_sleep" "wait_eks_access_seconds" {
  depends_on = [module.eks]

  create_duration = "60s"
}

resource "kubernetes_service_account" "external-dns" {
    depends_on = [time_sleep.wait_eks_access_seconds]
    count = var.create_external_dns ? 1 : 0
    metadata {
        name      = "external-dns"
        namespace = "kube-system"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.external_dns_irsa[0].iam_role_arn
        }
    }
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

  depends_on = [module.external_dns_irsa,
                time_sleep.wait_eks_access_seconds
                ]

}

output "eks_kubeconfig" {
  value = <<-EOT
    aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region} --role-arn ${aws_iam_role.eks_admin_role.arn}
  EOT
}