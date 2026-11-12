"""
TDD Test Suite: Healthcare AI & Genomic Telemedicine Data Lake Topology & Parsing.
Verifies that RegRadar's AST parser, reference extractor, and dependency graph builder
can accurately parse the complex multi-tier Healthcare & Genomic codebase and extract
all resource bindings without syntax errors or unresolvable references.
"""

from pathlib import Path
import pytest
from regradar.parser.hcl_parser import HCLParser
from regradar.graph.builder import DependencyGraphBuilder
from regradar.graph.centrality import CentralityEngine

TARGET_DIR = Path(__file__).parent.parent


def test_hcl_parser_discovers_all_healthcare_resources():
    """Verify HCL parser parses the healthcare genomic codebase into valid AST structures."""
    parser = HCLParser()
    resources = parser.parse_directory(TARGET_DIR)
    
    assert len(resources) >= 18, f"Expected at least 18 resources in complex Healthcare Lake, got {len(resources)}"
    
    resource_ids = set(resources.keys())
    # Verify core architectural tiers are represented
    assert "aws_vpc.healthcare_vpc" in resource_ids, "Missing root Healthcare VPC"
    assert "aws_subnet.telehealth_ingress_a" in resource_ids, "Missing telehealth ingress subnet"
    assert "aws_subnet.telehealth_app_a" in resource_ids, "Missing telehealth app subnet"
    assert "aws_subnet.genomic_ai_a" in resource_ids, "Missing genomic AI subnet"
    assert "aws_subnet.ephi_db_a" in resource_ids, "Missing ePHI DB subnet A"
    assert "aws_security_group.telehealth_alb_sg" in resource_ids, "Missing Telehealth ALB SG"
    assert "aws_security_group.telehealth_app_sg" in resource_ids, "Missing App Tier SG"
    assert "aws_security_group.genomic_ai_sg" in resource_ids, "Missing Genomic AI SG"
    assert "aws_security_group.ephi_db_sg" in resource_ids, "Missing ePHI DB SG"
    assert "aws_kms_key.ephi_kms_key" in resource_ids, "Missing ePHI KMS CMK"
    assert "aws_db_instance.ephi_postgresql_db" in resource_ids, "Missing ePHI RDS Database"
    assert "aws_s3_bucket.raw_genomics_lake" in resource_ids, "Missing Raw Genomics S3 Lake"
    assert "aws_s3_bucket.clinical_research_lake" in resource_ids, "Missing Clinical Research S3 Lake"
    assert "aws_cloudtrail.hipaa_cloudtrail" in resource_ids, "Missing HIPAA CloudTrail"
    assert "aws_instance.genomic_worker_a" in resource_ids, "Missing Genomic Worker EC2"


def test_healthcare_dependency_dag_structure():
    """Verify that the dependency DAG correctly models the multi-tier hierarchy."""
    parser = HCLParser()
    resources = parser.parse_directory(TARGET_DIR)
    builder = DependencyGraphBuilder(resources)
    dag = builder.graph

    assert len(builder.find_cycles()) == 0, "Dependency graph must be a strict DAG without cyclical deadlocks"

    # Dependency edge direction: Dependency -> Dependent (e.g. VPC -> Subnet)
    assert dag.has_edge("aws_vpc.healthcare_vpc", "aws_subnet.telehealth_ingress_a"), "VPC must precede ingress subnet"
    assert dag.has_edge("aws_vpc.healthcare_vpc", "aws_subnet.telehealth_app_a"), "VPC must precede app subnet"
    assert dag.has_edge("aws_vpc.healthcare_vpc", "aws_subnet.genomic_ai_a"), "VPC must precede genomic subnet"
    assert dag.has_edge("aws_vpc.healthcare_vpc", "aws_subnet.ephi_db_a"), "VPC must precede DB subnet"
    assert dag.has_edge("aws_vpc.healthcare_vpc", "aws_security_group.telehealth_alb_sg"), "VPC must precede ingress SG"
    
    # DB Subnet group depends on DB subnets
    assert dag.has_edge("aws_subnet.ephi_db_a", "aws_db_subnet_group.ephi_db_subnets") or \
           dag.has_edge("aws_subnet.ephi_db_b", "aws_db_subnet_group.ephi_db_subnets"), \
           "Subnet group must depend on DB subnets"

    # ePHI DB depends on DB subnet group and DB security group
    assert dag.has_edge("aws_security_group.ephi_db_sg", "aws_db_instance.ephi_postgresql_db"), \
           "ePHI DB must depend on DB Security Group"

    # Worker instance depends on Genomic Subnet and Genomic SG
    assert dag.has_edge("aws_subnet.genomic_ai_a", "aws_instance.genomic_worker_a"), \
           "Worker instance must depend on Genomic Subnet"
    assert dag.has_edge("aws_security_group.genomic_ai_sg", "aws_instance.genomic_worker_a"), \
           "Worker instance must depend on Genomic SG"


def test_healthcare_attribute_extraction_fidelity():
    """Verify detailed AST attribute extraction for healthcare resources."""
    parser = HCLParser()
    resources = parser.parse_directory(TARGET_DIR)

    vpc = resources["aws_vpc.healthcare_vpc"]
    assert "cidr_block" in vpc.attributes
    assert vpc.attributes["enable_dns_support"] is True

    db = resources["aws_db_instance.ephi_postgresql_db"]
    assert str(db.attributes["engine"]).strip('"') == "postgres"
    assert db.attributes["multi_az"] is True
    assert db.attributes["storage_encrypted"] is False

    kms = resources["aws_kms_key.ephi_kms_key"]
    assert kms.attributes["enable_key_rotation"] is True


def test_healthcare_graph_export_formats():
    """Verify Mermaid flowchart and Graphviz DOT exports produce valid diagrams."""
    parser = HCLParser()
    resources = parser.parse_directory(TARGET_DIR)
    builder = DependencyGraphBuilder(resources)
    engine = CentralityEngine(builder.graph)

    mermaid_content = engine.to_mermaid()
    assert mermaid_content.startswith("```mermaid\nflowchart TD")
    assert "aws_vpc_healthcare_vpc" in mermaid_content

    dot_content = engine.to_dot()
    assert "digraph" in dot_content
    assert "aws_vpc.healthcare_vpc" in dot_content
