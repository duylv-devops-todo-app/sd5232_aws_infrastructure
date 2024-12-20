# provider "aws" {
#   region = var.aws_region
# }
#
# resource "aws_vpc" "my_vpc" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#
#   tags = {
#     Name = "my-vpc"
#   }
# }
#
# resource "aws_subnet" "my_subnet" {
#   vpc_id                  = aws_vpc.my_vpc.id
#   cidr_block              = var.subnet_cidr
#   availability_zone       = var.availability_zone
#   map_public_ip_on_launch = true
#
#   tags = {
#     Name = "my-subnet"
#   }
# }
#
# resource "aws_internet_gateway" "my_igw" {
#   vpc_id = aws_vpc.my_vpc.id
#
#   tags = {
#     Name = "my-igw"
#   }
# }
#
# resource "aws_route_table" "my_route_table" {
#   vpc_id = aws_vpc.my_vpc.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.my_igw.id
#   }
#
#   tags = {
#     Name = "my-route-table"
#   }
# }
#
# resource "aws_route_table_association" "my_route_table_association" {
#   subnet_id      = aws_subnet.my_subnet.id
#   route_table_id = aws_route_table.my_route_table.id
# }
#
# # Security Group
# resource "aws_security_group" "ec2_sg" {
#   vpc_id      = aws_vpc.my_vpc.id
#   description = "Security Group for EC2"
#   name        = "ec2_sg"
#
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.allow_ssh_cidr]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "allow-ssh"
#   }
# }
#
# # EC2 instance
# resource "aws_instance" "my_instance" {
#   ami                      = var.ami_id
#   instance_type            = var.instance_type
#   subnet_id                = aws_subnet.my_subnet.id
#   vpc_security_group_ids   = [aws_security_group.ec2_sg.id]
#   associate_public_ip_address = true
#
#   tags = {
#     Name = "my-ec2-instance"
#   }
# }
#
# output "instance_public_ip" {
#   value = aws_instance.my_instance.public_ip
# }