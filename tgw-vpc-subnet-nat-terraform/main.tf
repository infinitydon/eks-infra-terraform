################################################################################
# VPC Module
################################################################################

module "vpc_ran" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.8.1"

  name = "vpc-ran"
  cidr = var.vpc_ran_cidr

  azs             = [var.ran_az1, var.ran_az2, var.ran_az1, var.ran_az1, var.ran_az1, var.ran_az1]
  private_subnets = [var.ran_eks_private_subnet_1, var.ran_eks_private_subnet_2, var.ran_f1_private_subnet, var.ran_e1_private_subnet, var.ran_n2_private_subnet, var.ran_n3_private_subnet]
  public_subnets  = [var.ran_public_subnet_1, var.ran_public_subnet_2]

  private_subnet_names = ["ran_Private_EKS_Subnet_One", "ran_Private_EKS_Subnet_Two", "ran_F1_Multus_Subnet", "ran_E1_Multus_Subnet", "ran_N2_Multus_Subnet", "ran_N3_Multus_Subnet"]
  public_subnet_names = ["ran_Public_Subnet_One", "ran_Public_Subnet_Two"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }  

}

module "vpc_core_controlplane" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.8.1"

  name = "vpc-controlplane"
  cidr = var.vpc_core_controlplane_cidr

  azs             = [var.core_controlplane_az1, var.core_controlplane_az2, var.core_controlplane_az1, var.core_controlplane_az1]
  private_subnets = [var.core_controlplane_eks_private_subnet_1, var.core_controlplane_eks_private_subnet_2, var.core_controlplane_core_n2_private_subnet, var.core_controlplane_core_n4_private_subnet]
  public_subnets  = [var.core_controlplane_public_subnet_1, var.core_controlplane_public_subnet_2]

  private_subnet_names = ["core_controlplane_Private_EKS_Subnet_One", "core_controlplane_Private_EKS_Subnet_Two", "core_controlplane_N2_Multus_Subnet", "core_controlplane_N4_Multus_Subnet"]
  public_subnet_names = ["core_controlplane_Public_Subnet_One", "core_controlplane_Public_Subnet_Two"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }  

}

module "vpc_core_userplane" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.8.1"

  name = "vpc-userplane"
  cidr = var.vpc_core_userplane_cidr

  azs             = [var.core_userplane_az1, var.core_userplane_az2, var.core_userplane_az1, var.core_userplane_az1, var.core_userplane_az1]
  private_subnets = [var.core_userplane_eks_private_subnet_1, var.core_userplane_eks_private_subnet_2, var.core_userplane_core_n3_private_subnet, var.core_userplane_core_n4_private_subnet, var.core_userplane_core_n6_private_subnet]
  public_subnets  = [var.core_userplane_public_subnet_1, var.core_userplane_public_subnet_2]

  private_subnet_names = ["core_userplane_Private_EKS_Subnet_One", "core_userplane_Private_EKS_Subnet_Two", "core_userplane_N3_Multus_Subnet", "core_userplane_N4_Multus_Subnet", "core_userplane_N6_Multus_Subnet"]
  public_subnet_names = ["core_userplane_Public_Subnet_One", "core_userplane_Public_Subnet_Two"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }  

}

## CIDR Reservation to dedicate speicific IP blocks for Multus subnets
resource "aws_ec2_subnet_cidr_reservation" "ran_f1" {
  cidr_block       = var.ran_f1_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_ran.private_subnets[2]
}

resource "aws_ec2_subnet_cidr_reservation" "ran_e1" {
  cidr_block       = var.ran_e1_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_ran.private_subnets[3]
}

resource "aws_ec2_subnet_cidr_reservation" "ran_n2" {
  cidr_block       = var.ran_n2_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_ran.private_subnets[4]
}

resource "aws_ec2_subnet_cidr_reservation" "ran_n3" {
  cidr_block       = var.ran_n3_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_ran.private_subnets[5]
}

resource "aws_ec2_subnet_cidr_reservation" "core_controlplane_core_n2" {
  cidr_block       = var.core_controlplane_core_n2_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_core_controlplane.private_subnets[2]
}

resource "aws_ec2_subnet_cidr_reservation" "core_controlplane_core_n4" {
  cidr_block       = var.core_controlplane_core_n4_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_core_controlplane.private_subnets[3]
}

resource "aws_ec2_subnet_cidr_reservation" "core_userplane_core_n3" {
  cidr_block       = var.core_userplane_core_n3_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_core_userplane.private_subnets[2]
}

resource "aws_ec2_subnet_cidr_reservation" "core_userplane_core_n4" {
  cidr_block       = var.core_userplane_core_n4_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_core_userplane.private_subnets[3]
}

resource "aws_ec2_subnet_cidr_reservation" "core_userplane_core_n6" {
  cidr_block       = var.core_userplane_core_n6_private_subnet_cidr_reservation
  reservation_type = "explicit"
  subnet_id        = module.vpc_core_userplane.private_subnets[4]
}

## Transit GW
resource "aws_ec2_transit_gateway" "telco_5G_tgw" {
  description = "TWG to connect RAN, Core and UPF"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_ran" {
  subnet_ids         = [module.vpc_ran.private_subnets[2]]
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
  vpc_id             = module.vpc_ran.vpc_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_core_controlplane" {
  subnet_ids         = [module.vpc_core_controlplane.private_subnets[3]]
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
  vpc_id             = module.vpc_core_controlplane.vpc_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_core_userplane" {
  subnet_ids         = [module.vpc_core_userplane.private_subnets[3]]
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
  vpc_id             = module.vpc_core_userplane.vpc_id
}

## Add routes towards to the TGW for all private subnets
resource "aws_route" "from_ran_to_controlplane_vpc" {
  route_table_id            = module.vpc_ran.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_core_controlplane_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

resource "aws_route" "from_ran_to_userplane_vpc" {
  route_table_id            = module.vpc_ran.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_core_userplane_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

resource "aws_route" "from_controlplane_to_ran_vpc" {
  route_table_id            = module.vpc_core_controlplane.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_ran_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

resource "aws_route" "from_controlplane_to_userplane_vpc" {
  route_table_id            = module.vpc_core_controlplane.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_core_userplane_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

resource "aws_route" "from_userplane_to_ran_vpc" {
  route_table_id            = module.vpc_core_userplane.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_ran_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

resource "aws_route" "from_userplane_to_controlplane_vpc" {
  route_table_id            = module.vpc_core_userplane.private_route_table_ids[0]
  destination_cidr_block    = var.vpc_core_controlplane_cidr
  transit_gateway_id = aws_ec2_transit_gateway.telco_5G_tgw.id
}

## Multus Security Groups
resource "aws_security_group" "ran_multus_sg" {
  name        = "Allow_CONTROLPLANE_USERPLANE_VPC_CIDR"
  description = "Allow necessary inbound traffic"
  vpc_id      = module.vpc_ran.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "Allow_ControlPlane_USERPLANE_VPC_CIDR"
  }
}

resource "aws_security_group" "core_controlplane_multus_sg" {
  name        = "Allow_RAN_USERPLANE_VPC_CIDR"
  description = "Allow necessary inbound traffic"
  vpc_id      = module.vpc_core_controlplane.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "Allow_RAN_USERPLANE_VPC_CIDR"
  }
}

resource "aws_security_group" "core_userplane_multus_sg" {
  name        = "Allow_RAN_CONTROLPLANE_VPC_CIDR"
  description = "Allow necessary inbound traffic"
  vpc_id      = module.vpc_core_userplane.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "Allow_RAN_CONTROLPLANE_VPC_CIDR"
  }
}

resource "aws_security_group_rule" "core_controlplane_multus_sg_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.core_controlplane_multus_sg.id
  source_security_group_id = aws_security_group.core_controlplane_multus_sg.id
  description       = "Allow traffic from within the same security group"
}

resource "aws_security_group_rule" "core_userplane_multus_sg_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.core_userplane_multus_sg.id
  source_security_group_id = aws_security_group.core_userplane_multus_sg.id
  description       = "Allow traffic from within the same security group"
}

resource "aws_security_group_rule" "ran_multus_sg_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ran_multus_sg.id
  source_security_group_id = aws_security_group.ran_multus_sg.id
  description       = "Allow traffic from within the same security group"
}

resource "aws_vpc_security_group_ingress_rule" "ran_allow_controlplane_traffic_ipv4" {
  security_group_id = aws_security_group.ran_multus_sg.id
  cidr_ipv4         = var.vpc_core_controlplane_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "ran_allow_userplane_traffic_ipv4" {
  security_group_id = aws_security_group.ran_multus_sg.id
  cidr_ipv4         = var.vpc_core_userplane_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "controlplane_allow_ran_traffic_ipv4" {
  security_group_id = aws_security_group.core_controlplane_multus_sg.id
  cidr_ipv4         = var.vpc_ran_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "controlplane_allow_userplane_traffic_ipv4" {
  security_group_id = aws_security_group.core_controlplane_multus_sg.id
  cidr_ipv4         = var.vpc_core_userplane_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "userplane_allow_ran_traffic_ipv4" {
  security_group_id = aws_security_group.core_userplane_multus_sg.id
  cidr_ipv4         = var.vpc_ran_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "userplane_allow_controlplane_traffic_ipv4" {
  security_group_id = aws_security_group.core_userplane_multus_sg.id
  cidr_ipv4         = var.vpc_core_controlplane_cidr
  ip_protocol       = "-1"
}