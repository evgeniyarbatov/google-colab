SHELL := /bin/sh
.ONESHELL:

VENV_PATH := .venv

PYTHON := $(VENV_PATH)/bin/python
PIP := $(VENV_PATH)/bin/pip
REQUIREMENTS := requirements.txt

NOTEBOOK_DIR := notebooks
NOTEBOOKS := $(shell find $(NOTEBOOK_DIR) -name "*.ipynb")

default: jupyter

venv:
	@python3 -m venv $(VENV_PATH)

requirements:
	@jq -r '.cells[].source[]?' $(NOTEBOOK_DIR)/*.ipynb | \
	python3 scripts/extract_imports.py > requirements.txt

install: venv
	@$(PIP) install --disable-pip-version-check -q --upgrade pip
	@$(PIP) install --disable-pip-version-check -q -r $(REQUIREMENTS)

	@$(PYTHON) -m ipykernel install \
	--user \
	--name google-colab \
	--display-name "google-colab"

jupyter:
	@cd $(NOTEBOOK_DIR) && jupyter lab

clear-kernel:
	jupyter nbconvert --ClearMetadataPreprocessor.enabled=True --inplace notebooks/**/*.ipynb

delete-kernels:
	jupyter kernelspec list --json | jq -r '.kernelspecs | keys[]' | xargs -n1 jupyter kernelspec remove -f

test-notebooks:
	fail=0
	echo "Running notebooks..."
	find notebooks -name "*.ipynb" -not -path "*/.ipynb_checkpoints/*" -print0 | \
	while IFS= read -r -d '' nb; do \
		echo "----------------------------------------"; \
		echo "Running $$nb"; \
		if jupyter nbconvert \
			--to notebook \
			--execute \
			--inplace \
			--ExecutePreprocessor.kernel_name=google-colab \
			--ExecutePreprocessor.timeout=600 \
			"$$nb"; then \
			echo "✅ OK: $$nb"; \
		else \
			echo "❌ ERROR: $$nb"; \
			fail=1; \
		fi; \
	done
	echo "----------------------------------------"
	if [ $$fail -eq 0 ]; then \
		echo "🎉 All notebooks ran successfully"; \
	else \
		echo "⚠️  Some notebooks failed"; \
	fi
	exit $$fail

cleanvenv:
	@rm -rf $(VENV_PATH)