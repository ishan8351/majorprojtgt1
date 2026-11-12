"""
TDD Test Suite: Healthcare Governance Benchmark & Empirical Evaluation.
Verifies that RegRadar's BenchmarkEvaluator computes empirical comparative metrics
for the Healthcare target codebase against an unconstrained generative AI baseline.
"""

from pathlib import Path
import pytest
from regradar.benchmark.evaluator import BenchmarkEvaluator
from regradar.benchmark.report_generator import ReportGenerator

TARGET_DIR = Path(__file__).parent.parent


def test_healthcare_benchmark_evaluation():
    """Verify benchmark run demonstrates safety advantage and 100% invariant preservation."""
    evaluator = BenchmarkEvaluator()
    result = evaluator.evaluate_target(TARGET_DIR)

    assert result.metrics.initial_violations >= 4
    assert result.metrics.remediation_rate > 0.0
    assert result.metrics.invariant_preservation_rate == 100.0, "RegRadar must enforce 100% invariant preservation rate"
    assert result.metrics.avoided_production_outages >= 1, "Must prevent at least 1 outage compared to unconstrained baseline"


def test_healthcare_comparative_ablation():
    """Verify comparative ablation highlights zero-destruction advantage."""
    evaluator = BenchmarkEvaluator()
    ablation = evaluator.run_comparative_ablation(TARGET_DIR)

    assert ablation.safety_differential_destructive_prevented >= 1
    assert ablation.regradar_metrics.invariant_preservation_rate == 100.0
    assert ablation.unconstrained_metrics.invariant_preservation_rate < 100.0


def test_healthcare_report_generation():
    """Verify Markdown and LaTeX report generators output valid telemetry tables."""
    evaluator = BenchmarkEvaluator()
    result = evaluator.evaluate_target(TARGET_DIR)
    ablation = evaluator.run_comparative_ablation(TARGET_DIR)
    gen = ReportGenerator()

    md_report = gen.generate_markdown_report(result, ablation=ablation)
    assert "RegRadar Empirical Governance Benchmark Report" in md_report
    assert "Invariant Preservation Rate" in md_report

    latex_table = gen.generate_latex_table(ablation)
    assert "\\begin{table}" in latex_table
    assert "\\end{table}" in latex_table
