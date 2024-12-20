# AWS Region
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet CIDR block
variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Availability Zone
variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

# AMI ID
variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

# Instance type
variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

# Allow SSH CIDR
variable "allow_ssh_cidr" {
  description = "CIDR block to allow SSH access"
  type        = string
  default     = "0.0.0.0/0" # Open to all
}

###########################################################################################
# VPC variable
###########################################################################################
variable "vpc_name" {
  type        = string
  description = "name of the vpc"
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "additional_private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

###########################################################################################
# EKS variables
###########################################################################################
variable "eks_cluster_name" {
  type        = string
  description = "eks cluster name"
}

variable "k8s_version" {
  type        = string
  description = "kubernetes version"
  default     = "1.27"
}

variable "workers_config" {
  type        = map(any)
  description = "workers config"
  default = {
    worker = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }
}

variable "eks_security_group_id" {
  default = "sg-eks"
}

