variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-08c40ec9ead489470" # Ubuntu 22.04 in us-east-1
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  description = "SSH key name"
}

variable "public_key" {
  description = "Public key material"
}

variable "private_key" {
  description = "Private key content"
}
