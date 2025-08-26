variable "key_name" {
  description = "Name for the EC2 key pair"
  type        = string
}

variable "public_key" {
  description = "Public SSH key contents (single-line OpenSSH format)"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  sensitive   = true
}
