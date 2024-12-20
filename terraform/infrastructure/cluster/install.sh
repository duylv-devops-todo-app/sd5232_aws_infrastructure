#!/bin/bash
#sudo yum update

# Install Jenkins
#sudo wget -O /etc/yum.repos.d/jenkins.repo \
#    https://pkg.jenkins.io/redhat-stable/jenkins.repo
#sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
#sudo yum upgrade
#sudo dnf install java-17-amazon-corretto -y
#sudo yum install jenkins -y

# Start Jenkins
#sudo systemctl enable jenkins
#sudo systemctl start jenkins

# Install git
#sudo yum install git -y

# Install git
#sudo yum install docker
#sudo systemctl start docker
#sudo usermod -a -G docker jenkins

# Install Kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.16/2024-11-15/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH