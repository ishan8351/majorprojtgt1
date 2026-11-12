# Makefile for Healthcare AI & Genomic Telemedicine Data Lake
.PHONY: all test scan remediate benchmark verify clean

PYTHON := python3
REGRADAR := python3 -m regradar.cli

all: test scan

test:
	PYTHONPATH=../majorproject pytest -v tests/

scan:
	PYTHONPATH=../majorproject $(REGRADAR) scan .

remediate:
	PYTHONPATH=../majorproject $(REGRADAR) remediate .

remediate-apply:
	PYTHONPATH=../majorproject $(REGRADAR) remediate . --apply

benchmark:
	PYTHONPATH=../majorproject $(REGRADAR) benchmark . --markdown benchmark_report.md

verify:
	PYTHONPATH=../majorproject $(REGRADAR) verify-sandbox .

clean:
	rm -rf .pytest_cache/ __pycache__/ tests/__pycache__/ benchmark_report.md
