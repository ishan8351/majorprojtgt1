# Healthcare AI & Genomic Telemedicine Data Lake

Enterprise multi-tier Infrastructure-as-Code (Terraform / OpenTofu) designed for clinical telemedicine, electronic Health Records (ePHI), whole-genome sequencing (WGS) ingestion pipelines, and statutory compliance under the **HIPAA Security Rule (45 CFR Part 160 & Part 164)**, **HITRUST CSF v11**, and **GDPR Article 9 (Special Categories: Genetic & Health Data)**.

This repository serves as a target infrastructure codebase for **RegRadar**, rigorously testing its topological blast-radius risk bounding, multi-agent compliance repair, and zero-destruction invariant verification.

---

## Architectural Overview

```
                                +-------------------------------+
                                |  Telehealth Ingress / Patients|
                                +---------------+---------------+
                                                |
                                                v (HTTPS :443)
                          +-------------------------------------------+
                          |   Telehealth Ingress Security Group (DMZ) |
                          +---------------------+---------------------+
                                                |
                       +------------------------+------------------------+
                       |                                                 |
                       v                                                 v
        +-------------------------------+               +-------------------------------+
        | Public Ingress Subnet A (1a)  |               | Public Ingress Subnet B (1b)  |
        |   - Telehealth Ingress ALB    |               |   - Telehealth Ingress ALB    |
        +---------------+---------------+               +---------------+---------------+
                       |                                                 |
                       v                                                 v
        +-------------------------------+               +-------------------------------+
        | Telehealth App Subnet A (1a)  |               | Telehealth App Subnet B (1b)  |
        |   - Clinical Telehealth APIs  |               |   - FHIR Interoperability Svc |
        +---------------+---------------+               +---------------+---------------+
                       |                                                 |
                       +------------------------+------------------------+
                                                |
                       +------------------------+------------------------+
                       |                                                 |
                       v (:8080)                                         v (:5432)
        +-------------------------------+               +-------------------------------+
        | Isolated Genomic Subnet (1a)  |               | Dedicated ePHI DB Subnet (1a) |
        |   - Genomic AI Worker (g5)    |               |   - Multi-AZ RDS PostgreSQL   |
        |   - Deep Learning Pipeline    |               |   - Encrypted Storage (CMK)   |
        +---------------+---------------+               +---------------+---------------+
                       |                                                 |
                       +------------------------+------------------------+
                                                |
                       +------------------------+------------------------+
                       |                                                 |
                       v                                                 v
        +-------------------------------+               +-------------------------------+
        |  KMS ePHI / Genomic CMK Keys  |               |  Genomic Sequencing S3 Lakes  |
        |   - Dual Independent Envelopes|               |   - Raw DNA Sequence Archive  |
        |   - Annual Automated Rotation |               |   - Clinical Research Vault   |
        +-------------------------------+               +-------------------------------+
```

---

## Topological Blast-Radius Stratification

RegRadar compiles the declarative HCL configuration into a directed dependency graph, assigning risk tiers based on betweenness centrality and cascading descendant ratios:

| Risk Tier | Infrastructure Components | Blast Radius Profile | Gating Decision |
| :--- | :--- | :---: | :--- |
| **`CRITICAL_ROOT`** | `aws_vpc.healthcare_vpc` | 18 downstream nodes ($S \ge 0.30$) | **Human Escalation:** Automated agent mutation strictly blocked. |
| **`INTERMEDIATE`** | `aws_subnet.*`, `aws_security_group.*`, `aws_db_subnet_group.*` | 1 to 4 downstream nodes | **Pre-Flight Sandbox:** Invariant diff verification mandatory. |
| **`LEAF_SAFE`** | `aws_s3_bucket.*`, `aws_kms_alias.*`, `aws_cloudtrail.*`, `aws_instance.*` | 0 downstream nodes ($S < 0.10$) | **Autonomous Eligible:** Multi-agent swarm synthesizes additive attachments. |

---

## Statutory Compliance Framework Matrix

| Regulation | Statute Reference | Checkov Check | Target Resource | Severity | RegRadar Remediation Mechanism |
| :--- | :--- | :---: | :--- | :---: | :--- |
| **HIPAA** | §164.312(a)(2)(iv) (Encryption at Rest) | `CKV_AWS_19` | `aws_s3_bucket.raw_genomics_lake` | HIGH | Standalone `aws_s3_bucket_server_side_encryption_configuration` |
| **HIPAA** | §164.308(a)(7) (Contingency Data Backup) | `CKV_AWS_21` | `aws_s3_bucket.clinical_research_lake` | MEDIUM | Standalone `aws_s3_bucket_versioning` attachment |
| **HIPAA** | §164.312(e)(1) (Transmission Security) | `CKV_AWS_24` | `aws_security_group.telehealth_alb_sg` | HIGH | Invariant-Gated SSH Ingress Lockout |
| **HIPAA** | §164.312(b) (Audit Controls) | `CKV_AWS_36` | `aws_cloudtrail.hipaa_cloudtrail` | HIGH | In-Place `kms_key_id` Envelope Binding |
| **HITRUST** | 01.m (Database Storage Protection) | `CKV_AWS_16` | `aws_db_instance.ephi_postgresql_db` | CRITICAL | Gated Pre-Flight Invariant (Outage Prevented) |
| **GDPR** | Art. 9 (Genetic Data Least Privilege) | `CKV_AWS_40` | `aws_iam_policy.genomic_processor_policy` | CRITICAL | Gated Human Review |

---

## Running Verification & Tests

```bash
# Run TDD test suite
PYTHONPATH=../majorproject pytest -v tests/

# Execute topological blast-radius scan
PYTHONPATH=../majorproject python -m regradar.cli scan .

# Run autonomous multi-agent remediation
PYTHONPATH=../majorproject python -m regradar.cli remediate .

# Run empirical governance benchmark
PYTHONPATH=../majorproject python -m regradar.cli benchmark .
```
