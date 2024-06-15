# Create a private hosted zone in the controlplane VPC, needed for NRF LB
resource "aws_route53_zone" "controlplane_internal" {
  name = "oai.internal"
  vpc {
    vpc_id = module.vpc_core_controlplane.vpc_id
  }
}

# Authorize the association of the additional VPC with the private hosted zone
resource "aws_route53_vpc_association_authorization" "userplane_auth" {
  vpc_id     = module.vpc_core_userplane.vpc_id
  vpc_region = var.region
  zone_id    = aws_route53_zone.controlplane_internal.zone_id
}

# Associate the additional VPC with the private hosted zone
resource "aws_route53_zone_association" "userplane_vpc" {
  zone_id = aws_route53_zone.controlplane_internal.zone_id
  vpc_id  = module.vpc_core_userplane.vpc_id
  depends_on = [aws_route53_vpc_association_authorization.userplane_auth]
}