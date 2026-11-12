terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# 1. FOUNDATIONAL HEALTHCARE NETWORK TOPOLOGY (ROOT DAG)
# ==============================================================================

resource "aws_vpc" "healthcare_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "healthcare-genomic-core-vpc"
    Environment = var.environment
    Compliance  = "HIPAA §164.312;HITRUST-CSF;GDPR-Art9"
    Tier        = "Foundation"
    ManagedBy   = "RegRadar"
  }
}

resource "aws_internet_gateway" "healthcare_igw" {
  vpc_id = aws_vpc.healthcare_vpc.id

  tags = {
    Name        = "healthcare-telehealth-igw"
    Environment = var.environment
    Compliance  = "HIPAA"
  }
}

# Public Telehealth Ingress DMZ Subnets (Dual AZ)
resource "aws_subnet" "telehealth_ingress_a" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "telehealth-public-ingress-a"
    Environment = var.environment
    Tier        = "Public"
  }
}

resource "aws_subnet" "telehealth_ingress_b" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "telehealth-public-ingress-b"
    Environment = var.environment
    Tier        = "Public"
  }
}

# Private Telehealth Application Subnets (Dual AZ)
resource "aws_subnet" "telehealth_app_a" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "telehealth-private-app-a"
    Environment = var.environment
    Tier        = "Application"
  }
}

resource "aws_subnet" "telehealth_app_b" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.20.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "telehealth-private-app-b"
    Environment = var.environment
    Tier        = "Application"
  }
}

# Private Isolated Genomic AI Processing Subnets (Dual AZ)
resource "aws_subnet" "genomic_ai_a" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.30.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "genomic-ai-pipeline-a"
    Environment = var.environment
    Tier        = "ComputeAI"
  }
}

resource "aws_subnet" "genomic_ai_b" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.40.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "genomic-ai-pipeline-b"
    Environment = var.environment
    Tier        = "ComputeAI"
  }
}

# Dedicated Isolated ePHI Database Subnets (Dual AZ ePHI Vault)
resource "aws_subnet" "ephi_db_a" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.50.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "ephi-isolated-database-a"
    Environment = var.environment
    Tier        = "Database"
    Compliance  = "HIPAA §164.312(a)(2)(iv) ePHI Vault"
  }
}

resource "aws_subnet" "ephi_db_b" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.80.60.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "ephi-isolated-database-b"
    Environment = var.environment
    Tier        = "Database"
    Compliance  = "HIPAA §164.312(a)(2)(iv) ePHI Vault"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.healthcare_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.healthcare_igw.id
  }

  tags = {
    Name = "healthcare-public-rt"
  }
}

resource "aws_route_table_association" "ingress_a_assoc" {
  subnet_id      = aws_subnet.telehealth_ingress_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "ingress_b_assoc" {
  subnet_id      = aws_subnet.telehealth_ingress_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_db_subnet_group" "ephi_db_subnets" {
  name       = "healthcare-ephi-db-subnet-group"
  subnet_ids = [aws_subnet.ephi_db_a.id, aws_subnet.ephi_db_b.id]

  tags = {
    Name        = "healthcare-ephi-db-subnet-group"
    Environment = var.environment
  }
}

# ==============================================================================
# 2. ZERO-TRUST PERIMETER & MICROSEGMENTATION SECURITY GROUPS
# ==============================================================================

# Statutory Smell 1 & 2:
# - CKV_AWS_24: Ingress from 0.0.0.0/0 on port 22 (SSH)
# - CKV_AWS_23: Security group missing description
resource "aws_security_group" "telehealth_alb_sg" {
  name   = "healthcare-telehealth-alb-sg"
  vpc_id = aws_vpc.healthcare_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "telehealth-alb-sg"
    Compliance = "HIPAA §164.312(e)(1)"
  }
}

resource "aws_security_group" "telehealth_app_sg" {
  name        = "healthcare-app-sg"
  description = "Security group for HIPAA telehealth application services"
  vpc_id      = aws_vpc.healthcare_vpc.id

  ingress {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.telehealth_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "healthcare-app-sg"
  }
}

resource "aws_security_group" "genomic_ai_sg" {
  name        = "healthcare-genomic-ai-sg"
  description = "Security group for deep genomic sequence analytics workers"
  vpc_id      = aws_vpc.healthcare_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.telehealth_app_sg.id]
  }

  tags = {
    Name = "genomic-ai-sg"
  }
}

resource "aws_security_group" "ephi_db_sg" {
  name        = "healthcare-ephi-db-sg"
  description = "Zero-trust database security group for ePHI repository"
  vpc_id      = aws_vpc.healthcare_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.telehealth_app_sg.id, aws_security_group.genomic_ai_sg.id]
  }

  tags = {
    Name = "ephi-db-sg"
  }
}

# ==============================================================================
# 3. CRYPTOGRAPHIC KEY MANAGEMENT (KMS CMK)
# ==============================================================================

resource "aws_kms_key" "ephi_kms_key" {
  description             = "Customer Managed Key for ePHI health records and HIPAA telemedicine"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "healthcare-ephi-cmk"
    Environment = var.environment
    Compliance  = "HIPAA §164.312(a)(2)(iv);HITRUST 01.i"
  }
}

resource "aws_kms_alias" "ephi_kms_alias" {
  name          = "alias/healthcare-ephi-key"
  target_key_id = aws_kms_key.ephi_kms_key.key_id
}

resource "aws_kms_key" "genomic_kms_key" {
  description             = "Customer Managed Key for genomic DNA sequences"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "healthcare-genomics-cmk"
    Compliance  = "GDPR Art 9;HIPAA §164.312"
    Environment = var.environment
  }
}

# ==============================================================================
# 4. STATEFUL ELECTRONIC HEALTH RECORDS (EHR) DATABASE (RDS POSTGRESQL)
# ==============================================================================

# Statutory Smell 3:
# - CKV_AWS_16: Database storage encryption disabled (storage_encrypted = false)
resource "aws_db_instance" "ephi_postgresql_db" {
  identifier             = "healthcare-ephi-postgres-db"
  allocated_storage      = 150
  max_allocated_storage  = 1000
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.2xlarge"
  db_name                = "ephirecords"
  username               = "hipaamaster"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.ephi_db_subnets.name
  vpc_security_group_ids = [aws_security_group.ephi_db_sg.id]
  multi_az               = true
  skip_final_snapshot    = true
  storage_encrypted      = false

  tags = {
    Name        = "healthcare-ephi-database"
    Environment = var.environment
    Compliance  = "HIPAA §164.312(a)(2)(iv);HITRUST 01.m"
  }
}

# ==============================================================================
# 5. MULTI-TIER GENOMIC & TELEMEDICINE DATA LAKES (S3)
# ==============================================================================

# Statutory Smells 4 & 5:
# - CKV_AWS_19: S3 bucket unencrypted by default
# - CKV_AWS_21: S3 bucket missing object versioning
resource "aws_s3_bucket" "raw_genomics_lake" {
  bucket = "healthcare-raw-genomics-sequencing-lake-prod"

  tags = {
    Name        = "healthcare-raw-genomics-lake"
    Environment = var.environment
    Compliance  = "HIPAA §164.312;GDPR Art 9"
    DataType    = "WholeGenomeSequencing"
  }
}

resource "aws_s3_bucket" "clinical_research_lake" {
  bucket = "healthcare-clinical-telehealth-research-lake-prod"

  tags = {
    Name        = "healthcare-clinical-research-lake"
    Environment = var.environment
    Compliance  = "HIPAA §164.314;HITRUST 09.f"
    DataType    = "DeIdentifiedResearch"
  }
}

resource "aws_s3_bucket" "hipaa_audit_logs" {
  bucket = "healthcare-hipaa-statutory-audit-logs-prod"

  tags = {
    Name        = "healthcare-hipaa-audit-logs"
    Environment = var.environment
    Compliance  = "HIPAA §164.312(b);NIST SP 800-53 AU-3"
  }
}

# ==============================================================================
# 6. STATUTORY TELEMETRY & AUDIT TRAILS (CLOUDTRAIL)
# ==============================================================================

# Statutory Smell 6:
# - CKV_AWS_36: CloudTrail trail missing KMS Master Key encryption
resource "aws_cloudtrail" "hipaa_cloudtrail" {
  name                          = "healthcare-ehr-access-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.hipaa_audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  tags = {
    Name        = "healthcare-hipaa-trail"
    Compliance  = "HIPAA §164.312(b);HITRUST 09.aa"
    Environment = var.environment
  }
}

# ==============================================================================
# 7. IDENTITY & GENOMIC COMPUTE PIPELINE
# ==============================================================================

# Statutory Smell 7:
# - CKV_AWS_40: Unconstrained IAM wildcard policy ("Action": "*")
resource "aws_iam_policy" "genomic_processor_policy" {
  name        = "healthcare-genomic-worker-policy"
  description = "Execution role policy for deep genomic analytics workers"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "genomic_worker_role" {
  name = "healthcare-genomic-pipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "genomic_worker_attach" {
  role       = aws_iam_role.genomic_worker_role.name
  policy_arn = aws_iam_policy.genomic_processor_policy.arn
}

resource "aws_iam_instance_profile" "genomic_worker_profile" {
  name = "healthcare-genomic-worker-profile"
  role = aws_iam_role.genomic_worker_role.name
}

# Statutory Smell 8:
# - CKV_AWS_79: EC2 Instance missing IMDSv2 enforcement
resource "aws_instance" "genomic_worker_a" {
  ami                  = "ami-0c55b159cbfafe1f0"
  instance_type        = "g5.4xlarge"
  subnet_id            = aws_subnet.genomic_ai_a.id
  iam_instance_profile = aws_iam_instance_profile.genomic_worker_profile.name
  vpc_security_group_ids = [
    aws_security_group.genomic_ai_sg.id
  ]

  tags = {
    Name        = "healthcare-genomic-model-worker-a"
    Environment = var.environment
    Compliance  = "HIPAA §164.312;GDPR Art 9"
  }
}
