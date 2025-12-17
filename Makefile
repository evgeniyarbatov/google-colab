SHELL := /bin/sh
.ONESHELL:

NOTEBOOK_DIR := notebooks
NOTEBOOKS := $(shell find $(NOTEBOOK_DIR) -name "*.ipynb")

default: jupyter

jupyter:
	@jupyter lab

clear-kernel:
	jupyter nbconvert --ClearMetadataPreprocessor.enabled=True --inplace notebooks/**/*.ipynb

delete-kernels:
	jupyter kernelspec list --json | jq -r '.kernelspecs | keys[]' | grep -v python3 | xargs -n1 jupyter kernelspec remove -f

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