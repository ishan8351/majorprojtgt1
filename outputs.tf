output "healthcare_vpc_id" {
  description = "Identifier of the primary Healthcare core VPC"
  value       = aws_vpc.healthcare_vpc.id
}

output "telehealth_ingress_subnets" {
  description = "Identifiers of public telehealth ingress subnets"
  value       = [aws_subnet.telehealth_ingress_a.id, aws_subnet.telehealth_ingress_b.id]
}

output "genomic_ai_subnets" {
  description = "Identifiers of isolated genomic AI compute subnets"
  value       = [aws_subnet.genomic_ai_a.id, aws_subnet.genomic_ai_b.id]
}

output "ephi_db_subnets" {
  description = "Identifiers of isolated ePHI database subnets"
  value       = [aws_subnet.ephi_db_a.id, aws_subnet.ephi_db_b.id]
}

output "ephi_db_endpoint" {
  description = "Connection endpoint for the primary ePHI database"
  value       = aws_db_instance.ephi_postgresql_db.endpoint
}

output "raw_genomics_bucket" {
  description = "S3 bucket for raw genomic sequence data"
  value       = aws_s3_bucket.raw_genomics_lake.bucket
}

output "ephi_kms_key_arn" {
  description = "ARN of the ePHI Customer Managed Key"
  value       = aws_kms_key.ephi_kms_key.arn
}
