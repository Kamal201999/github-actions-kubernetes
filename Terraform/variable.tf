variable "key_name" {
  description = "Name for the EC2 key pair"
  type        = string
}

variable "public_key" {
  description = "public SSH key content"
  type        = string
}

variable "private_key_path" {
  description = "Private key contents for remote-exec"
  type        = string
}
