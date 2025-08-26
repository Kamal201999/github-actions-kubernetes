provider "aws" {
  region = var.region != "" ? var.region : "us-east-1"
}

# ✅ Create EC2 Key Pair using public key
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key   # 👈 FIX: use string, no need to read from file
}

# ✅ Example EC2 instance with SSH connection
resource "aws_instance" "minikube_ec2" {
  ami           = "ami-08c40ec9ead489470" # Ubuntu 22.04 in us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  tags = {
    Name = "minikube-ec2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key   # 👈 FIX: now works because we pass contents
    host        = self.public_ip
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from Terraform EC2 instance!'"
    ]
  }
}
