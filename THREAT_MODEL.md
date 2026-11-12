# Healthcare AI & Genomic Lake STRIDE Threat Model

This document specifies the STRIDE threat analysis for the Healthcare AI & Genomic Telemedicine Data Lake.

---

## 1. STRIDE Analysis Matrix

| Threat Category | Healthcare Threat Scenario | Impact Level | Architectural Mitigation | RegRadar Invariant Defense |
| :--- | :--- | :---: | :--- | :--- |
| **Spoofing (S)** | Malicious actor steals temporary IAM credentials from the genomic AI worker via SSRF. | CRITICAL | EC2 IMDSv2 token enforcement (`http_tokens = "required"`). | `CKV_AWS_79` enforced on `aws_instance.genomic_worker_a`. |
| **Tampering (T)** | Unauthenticated user alters genomic sequencing reads or patient clinical records. | CRITICAL | Immutable S3 Object Versioning + KMS Customer Managed Key encryption. | Additive `aws_s3_bucket_versioning` attachment injected. |
| **Repudiation (R)** | Malicious insider accesses ePHI medical history without an immutable audit record. | HIGH | Multi-region AWS CloudTrail logging with KMS envelope encryption. | `CKV_AWS_36` enforced on `aws_cloudtrail.hipaa_cloudtrail`. |
| **Information Disclosure (I)** | Raw genetic sequence files or patient records leaked via an unencrypted S3 bucket. | CATASTROPHIC | Default SSE-KMS encryption + Public Access Block + Microsegmented SGs. | Additive `aws_s3_bucket_server_side_encryption_configuration` applied. |
| **Denial of Service (D)** | Automated AI repair modifies root VPC CIDR or deletes database subnet group, taking hospital offline. | FATAL | Topological blast-radius gating ($S \ge 0.30$) + Ephemeral plan diff verification. | `aws_vpc.healthcare_vpc` gated as `CRITICAL_ROOT`; 0 deletions allowed. |
| **Elevation of Privilege (E)** | Compromised AI training job leverages wildcard IAM policy to exfiltrate entire clinical database. | CRITICAL | Least-privilege IAM policy restricting wildcard administrative privileges. | `CKV_AWS_40` detected and routed to human security team. |

---

## 2. Genomic Pipeline Attack Surface Reductions

1. **Isolation of Heavy Genomic Compute:**
   * High-throughput genomic training jobs run in `aws_subnet.genomic_ai_a`, which cannot be accessed directly from the public internet. All ingress must traverse the private application layer.
2. **Deterministic Invariant Protection against State Teardowns:**
   * Traditional LLM repair agents frequently attempt to alter `aws_db_instance` parameters (e.g. database `engine` or `identifier`), which forces AWS to delete the old database and recreate a new one, destroying patient health histories.
   * RegRadar's supervisor intercepts the resulting `tofu plan -json` output, detects `["delete", "create"]`, and blocks the patch.
