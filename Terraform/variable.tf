variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "private_key" {   # 👈 FIX: changed from file path → raw string
  description = "Private key contents for connecting to EC2"
  type        = string
  sensitive   = true
}
