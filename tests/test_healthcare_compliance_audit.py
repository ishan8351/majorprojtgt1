"""
TDD Test Suite: Healthcare Compliance Audit & Statutory Smell Identification.
Verifies that RegRadar's CheckovScanner (with AST fallback) successfully detects
intentional compliance violations across HIPAA §164.312, HITRUST CSF, and GDPR Article 9
in the Healthcare AI & Genomic Telemedicine Data Lake.
"""

from pathlib import Path
import pytest
from regradar.remediation.scanner import CheckovScanner
from regradar.knowledge.catalog import get_default_catalog

TARGET_DIR = Path(__file__).parent.parent


def test_healthcare_compliance_violations_detected():
    """Verify that intentional compliance violations in the Healthcare Lake are identified."""
    scanner = CheckovScanner()
    violations = scanner.scan_directory(TARGET_DIR)

    assert len(violations) >= 4, f"Expected at least 4 compliance violations in Healthcare codebase, got {len(violations)}"

    check_ids = {v.check_id for v in violations}
    # Verify core HIPAA compliance checks
    assert "CKV_AWS_19" in check_ids or "CKV_AWS_145" in check_ids, "Should detect unencrypted S3 genomic bucket"
    assert "CKV_AWS_21" in check_ids, "Should detect S3 bucket without object versioning"
    assert "CKV_AWS_16" in check_ids, "Should detect unencrypted ePHI database storage"
    assert "CKV_AWS_36" in check_ids or "CKV_AWS_40" in check_ids or "CKV_AWS_23" in check_ids, \
        "Should detect CloudTrail, IAM, or SG violation"


def test_healthcare_violation_framework_attribution():
    """Verify that discovered violations cite HIPAA, GDPR, or NIST statutory frameworks."""
    scanner = CheckovScanner()
    violations = scanner.scan_directory(TARGET_DIR)

    all_frameworks = []
    for v in violations:
        all_frameworks.extend(v.frameworks)

    framework_text = " ".join(all_frameworks)
    assert "HIPAA" in framework_text or "GDPR" in framework_text or "NIST" in framework_text, \
        "Violations must map to HIPAA, GDPR, or NIST compliance standards"


def test_healthcare_specific_resource_violations():
    """Verify exact resource attribution for candidate smells."""
    scanner = CheckovScanner()
    violations = scanner.scan_directory(TARGET_DIR)

    violation_map = {v.resource_id: v.check_id for v in violations}
    assert "aws_s3_bucket.raw_genomics_lake" in violation_map
    assert "aws_db_instance.ephi_postgresql_db" in violation_map
    assert "aws_security_group.telehealth_alb_sg" in violation_map


def test_healthcare_custom_organizational_rule_discovery():
    """Verify that RegRadar dynamically discovers custom healthcare rules."""
    stds, ctrls, reqs, res, rules = get_default_catalog()
    assert "CKV_HEALTHCARE_01" in rules, "Custom rule CKV_HEALTHCARE_01 must be dynamically loaded from rules/custom/"
    rule = rules["CKV_HEALTHCARE_01"]
    assert rule.resource_type == "aws_s3_bucket"
    assert "HIPAA" in rule.framework
