provider "aws" {
}

# Use the default VPC
data "aws_vpc" "default" {
 filter {
   name = "isDefault"
  values = ["true"]
} 
}

# Use the first subnet in the default VPC
data "aws_subnets" "default" {
 filter {
   name = "vpc-id"
  values = [data.aws_vpc.default.id]
} 
}

# Create SSH key pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}

# Security group to allow SSH and NodePort range
resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and Kubernetes"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 instance with Minikube setup
resource "aws_instance" "minikube_ec2" {
  ami                         = "ami-0c02fb55956c7d316" # Ubuntu 20.04 LTS for us-east-1
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.minikube_sg.id]

  root_block_device {
    volume_size = 20
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io conntrack socat ebtables",
      "sudo usermod -aG docker ubuntu",
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "sudo minikube start --driver=none",
      "curl -LO https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "2m"
    }
  }

  tags = {
    Name = "minikube-ec2"
  }
}

# Output EC2 public IP
output "ec2_public_ip" {
  value = aws_instance.minikube_ec2.public_ip
}
