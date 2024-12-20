aws_region        = "us-east-1"
vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"
availability_zone = "us-east-1a"
ami_id            = "ami-01816d07b1128cd2d"
# instance_type     = "t3.large"
instance_type     = "t2.micro"
allow_ssh_cidr    = "0.0.0.0/0"
vpc_name          = "vpc_cluster"
eks_cluster_name  = "eks_cluster"