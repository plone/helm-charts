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

CHART_DIR := charts/plone
# Kubernetes versions to validate the manifests against: the oldest that the
# chart supports (kubeVersion in Chart.yaml), one in between, and the one of
# the CI cluster.
KUBE_VERSIONS ?= 1.29.0 1.33.0 1.37.0
# The tools run in containers, so that they need no installation.
HELM_UNITTEST_IMAGE ?= helmunittest/helm-unittest:4.3.0-1.2.1
KUBECONFORM_IMAGE ?= ghcr.io/yannh/kubeconform:v0.8.0
# Schemas of the custom resources that the chart creates, such as the Gateway
# API HTTPRoute.
KUBECONFORM_CRD_SCHEMAS := https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
# Kinds not to validate. The cnpg cluster chart renders an empty
# spec.postgresql in the Cluster, which the API server prunes, but which the
# schema refuses.
KUBECONFORM_SKIP ?= Cluster

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: chart-deps
chart-deps: ## Fetch the dependencies of the chart
	@echo -e "$(GREEN)==> Fetch the chart dependencies$(RESET)"
	@helm repo add cnpg https://cloudnative-pg.github.io/charts --force-update > /dev/null
	@helm dependency build $(CHART_DIR) > /dev/null

.PHONY: test
test: test-unit test-manifests ## Run the unit tests, and validate the manifests

.PHONY: test-unit
test-unit: chart-deps ## Run the unit tests of the chart, in charts/plone/tests (helm-unittest)
	@echo -e "$(GREEN)==> Run the unit tests$(RESET)"
	@# As the owner of the checkout, so that helm-unittest can create
	@# tests/__snapshot__: the image runs as uid 1000.
	@docker run --rm --user "$$(id -u):$$(id -g)" -e HOME=/tmp \
		-v "$(CURDIR)/$(CHART_DIR):/apps" $(HELM_UNITTEST_IMAGE) .

.PHONY: test-manifests
test-manifests: chart-deps ## Validate the manifests of each CI scenario against the schemas of KUBE_VERSIONS (kubeconform)
	@echo -e "$(GREEN)==> Validate the manifests$(RESET)"
	@# make 3.81, on macOS, ignores .SHELLFLAGS: fail explicitly on any error.
	@set -o pipefail; \
	for version in $(KUBE_VERSIONS); do \
		for values in $(CHART_DIR)/ci/*-values.yaml; do \
			echo "Kubernetes $$version, $$(basename $$values):"; \
			helm template plone $(CHART_DIR) --kube-version $$version --values $$values \
				| docker run --rm -i $(KUBECONFORM_IMAGE) -strict -summary \
					-kubernetes-version $$version -skip '$(KUBECONFORM_SKIP)' \
					-schema-location default -schema-location '$(KUBECONFORM_CRD_SCHEMAS)' - \
				|| exit 1; \
		done; \
	done

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
