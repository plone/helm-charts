### Defensive settings for make:
#     https://tech.davis-hansson.com/p/make/
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
RESET := \033[0m

UV ?= uv
DOCS_DIR := docs
DOCS_BUILDDIR := $(DOCS_DIR)/_build
DOCS_SPHINXOPTS ?=
DOCS_VALEOPTS ?=
DOCS_VALEFILES = $(shell find $(DOCS_DIR) -type f -name "*.md" -not -path "$(DOCS_BUILDDIR)/*" -not -path "$(DOCS_DIR)/_styles/*" -print)
# Branch where chart-releaser keeps the index of the Helm repository.
PAGES_BRANCH ?= gh-pages

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install the documentation tools
	@echo -e "$(GREEN)==> Install documentation tools$(RESET)"
	@$(UV) sync --group docs

.PHONY: docs
docs: ## Build the documentation (warnings are errors)
	@echo -e "$(GREEN)==> Build documentation$(RESET)"
	@$(UV) run --group docs sphinx-build -W --keep-going -b html $(DOCS_DIR) "$(DOCS_BUILDDIR)/html" $(DOCS_SPHINXOPTS)

.PHONY: docs-site
docs-site: docs ## Build the GitHub Pages site: the documentation and the index of the Helm repository
	@echo -e "$(GREEN)==> Add the Helm repository index from $(PAGES_BRANCH)$(RESET)"
	@git fetch --quiet origin $(PAGES_BRANCH)
	@git show FETCH_HEAD:index.yaml > "$(DOCS_BUILDDIR)/html/index.yaml"
	@grep -q '^apiVersion: v1' "$(DOCS_BUILDDIR)/html/index.yaml"

.PHONY: docs-livehtml
docs-livehtml: ## Rebuild the documentation on changes, with live reload in the browser
	@$(UV) run --group docs sphinx-autobuild --ignore "*.swp" --port 8050 \
		-b html $(DOCS_DIR) "$(DOCS_BUILDDIR)/html" $(DOCS_SPHINXOPTS)

.PHONY: docs-linkcheck
docs-linkcheck: ## Check that all links in the documentation resolve
	@echo -e "$(GREEN)==> Check documentation links$(RESET)"
	@$(UV) run --group docs sphinx-build -b linkcheck $(DOCS_DIR) "$(DOCS_BUILDDIR)/linkcheck"

.PHONY: docs-vale
docs-vale: ## Check the documentation with Vale
	@echo -e "$(GREEN)==> Check documentation with Vale$(RESET)"
	@$(UV) run --group docs vale sync
	@$(UV) run --group docs vale --no-wrap $(DOCS_VALEOPTS) $(DOCS_VALEFILES)

.PHONY: docs-clean
docs-clean: ## Remove the built documentation
	@echo -e "$(RED)==> Clean documentation$(RESET)"
	@rm -rf "$(DOCS_BUILDDIR)"
