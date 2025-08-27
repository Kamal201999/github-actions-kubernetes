provider "aws" {
  region = "us-east-1"
}

# Custom VPC Creation
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "custom-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# SSH key pair resource
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and Kubernetes"
  vpc_id = aws_vpc.custom_vpc.id

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

resource "aws_instance" "minikube_ec2" {
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  root_block_device {
    volume_size = 20
  }

  provisioner "remote-exec" {
    when = "create"
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io conntrack socat ebtables",
      "sudo usermod -aG docker ubuntu",
      "curl -LO https://storage.googleapis.com/minikube/releases/v1.34.0/minikube-linux-amd64",  # latest version
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "curl -LO https://dl.k8s.io/release/v1.33.3/bin/linux/amd64/kubectl",
      "chmod +x kubectl && sudo mv kubectl /usr/local/bin/",
      "bash -c 'newgrp docker <<EOF\nminikube start --driver=docker --kubernetes-version=v1.33.3\nEOF'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
      timeout     = "2m"
    }
  }

  tags = {
    Name = "minikube-ec2"
  }
}

output "ec2_public_ip" {
  value = aws_instance.minikube_ec2.public_ip
}
