provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  intra_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]

  ebs_csi_service_account_namespace = "kube-system"
  ebs_csi_service_account_name      = "ebs-csi-controller-sa"

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
  azs = local.azs

  # vpc cidr
  cidr = var.vpc_cidr

  # public and private subnets
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  # create nat gateways
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  one_nat_gateway_per_az  = false

  # enable dns hostnames and support
  enable_dns_hostnames    = true
  enable_dns_support      = var.enable_dns_support

  # tags for public, private subnets and vpc
  tags               = var.tags

  # create internet gateway
  create_igw       = var.create_igw
  instance_tenancy = var.instance_tenancy

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }
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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access for Jenkinsfile
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
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name = var.eks_cluster_name
  cluster_version = var.k8s_version

  # vpc & subnet
  vpc_id                   = module.vpc_and_subnets.vpc_id
  subnet_ids               = module.vpc_and_subnets.private_subnets
  control_plane_subnet_ids = module.vpc_and_subnets.intra_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

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
      most_recent              = true
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.eks.cluster_name}-ebs-csi-controller"
    }
  }

  # work around for issue https://stackoverflow.com/questions/74687452/eks-error-syncing-load-balancer-failed-to-ensure-load-balancer-multiple-tagge
  node_security_group_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = null
  }

  # Add inbound rule, allow access from EC2.
  cluster_security_group_additional_rules = {
    ingress_ec2_tcp = {
      description              = "Access EKS from EC2 instance."
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.ec2_sg.id
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    amc-cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      # instance_types = ["t3.large"]
      instance_types = ["t2.medium"]
      capacity_type = "SPOT"
    }
  }
}

###########################################################################################
# ECR
###########################################################################################
resource "aws_ecr_repository" "cluster_ecr_fe" {
  name = var.ecr_fe_name
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

resource "aws_ecr_repository" "cluster_ecr_be" {
  name = var.ecr_be_name
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
# ebs csi
###########################################################################################
module "ebs_csi_controller_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.11.1"
  create_role                   = true
  role_name                     = "${var.eks_cluster_name}-ebs-csi-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.ebs_csi_controller.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.ebs_csi_service_account_namespace}:${local.ebs_csi_service_account_name}"
  ]
}

resource "aws_iam_policy" "ebs_csi_controller" {
  name_prefix = "ebs-csi-controller"
  description = "EKS ebs-csi-controller policy for cluster ${var.eks_cluster_name}"
  policy = file("./ebs_csi_controller_iam_policy.json")
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

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = local.ec2_name
  }
}