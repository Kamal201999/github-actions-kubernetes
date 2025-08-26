provider "aws" {
  # Credentials and region picked from environment variables:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ci-cicd-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "ci-cicd-subnet"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and Kubernetes"
  vpc_id      = aws_vpc.main.id

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
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

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

output "ec2_public_ip" {
  value = aws_instance.minikube_ec2.public_ip
}
