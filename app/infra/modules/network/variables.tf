# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名 (dev/prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment は 'dev' または 'prod' である必要があります"
  }
}

variable "availability_zone" {
  description = "アベイラビリティゾーン"
  type        = string
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr は有効な CIDR ブロックである必要があります"
  }
}

variable "public_subnet_cidr" {
  description = "Public Subnet の CIDR ブロック"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr は有効な CIDR ブロックである必要があります"
  }
}

variable "private_subnet_cidr" {
  description = "Private Subnet の CIDR ブロック"
  type        = string
  default     = "10.0.10.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr は有効な CIDR ブロックである必要があります"
  }
}
