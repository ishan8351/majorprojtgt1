variable "aws_region" {
  type        = string
  description = "AWS region for healthcare telemedicine & genomic pipeline"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment lifecycle stage"
  default     = "production"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the core Healthcare VPC"
  default     = "10.80.0.0/16"
}

variable "db_password" {
  type        = string
  description = "Master password for ePHI PostgreSQL database"
  default     = "HealthcareMasterSecretKey2026!#"
  sensitive   = true
}
