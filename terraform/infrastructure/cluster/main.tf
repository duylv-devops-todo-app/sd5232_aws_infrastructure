provider "aws" {
  region = var.aws_region
}

# to retrieve the availability zones
data "aws_availability_zones" "available" {}

locals {

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  intra_subnets = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]

  ec2_name = "my-ec2-instance"
}

###########################################################################################
# VPC, subnet, etc.
###########################################################################################
module "vpc_and_subnets" {
  # invoke public vpc module
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  # vpc name
  name = var.vpc_name

  # availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # vpc cidr
  cidr = var.vpc_cidr

  # public and private subnets
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets = local.intra_subnets

  # create nat gateways
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # enable dns hostnames and support
  enable_dns_hostnames = true
  enable_dns_support = var.enable_dns_support

  # tags for public, private subnets and vpc
  tags               = var.tags
  public_subnet_tags = var.additional_public_subnet_tags
  private_subnet_tags = var.additional_private_subnet_tags

  # create internet gateway
  create_igw       = var.create_igw
  instance_tenancy = var.instance_tenancy

}

resource "aws_security_group" "ec2_sg" {
  vpc_id      = module.vpc_and_subnets.vpc_id
  description = "Security Group for EC2"
  name        = "ec2_sg"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  # Allow access for Jenkins
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
  }
}

###########################################################################################
# EKS, EKS Security Group
###########################################################################################
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.15.3"
#
#   cluster_name = var.eks_cluster_name
#   cluster_version = var.k8s_version
#
#   # vpc & subnet
#   vpc_id                   = module.vpc_and_subnets.vpc_id
#   subnet_ids               = module.vpc_and_subnets.private_subnets
#   control_plane_subnet_ids = module.vpc_and_subnets.intra_subnets
#
#   cluster_endpoint_public_access = true
#   enable_irsa                    = true
#
#   cluster_addons = {
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#   }
#
#   # Add inbound rule, allow access from EC2.
#   cluster_security_group_additional_rules = {
#     ingress_ec2_tcp = {
#       description              = "Access EKS from EC2 instance."
#       protocol                 = "tcp"
#       from_port                = 443
#       to_port                  = 443
#       type                     = "ingress"
#       source_security_group_id = aws_security_group.ec2_sg.id
#     }
#   }
#
#   eks_managed_node_group_defaults = {
#     ami_type                              = "AL2_x86_64"
#     instance_types = ["m5.large"]
#     attach_cluster_primary_security_group = true
#   }
#
#   eks_managed_node_groups = {
#     amc-cluster-wg = {
#       min_size     = 1
#       max_size     = 2
#       desired_size = 1
#
#       instance_types = ["t3.large"]
#       capacity_type = "SPOT"
#     }
#   }
# }

###########################################################################################
# ECR
###########################################################################################
resource "aws_ecr_repository" "example" {
  name = var.ecr_name
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = true

  tags = {
    Team = "DevOps"
  }
}


###########################################################################################
# EC2 instance
###########################################################################################
resource "aws_instance" "my_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = module.vpc_and_subnets.public_subnets[0]
  associate_public_ip_address = true

  user_data = file("install.sh") # install needed stuff on start up.

  tags = {
    Name = local.ec2_name
  }
}