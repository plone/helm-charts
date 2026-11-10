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

# What make cluster-deps installs in the cluster of make test-install, as in CI.
CNPG_REPO := https://cloudnative-pg.github.io/charts
CNPG_OPERATOR_VERSION ?= 0.29.1
GATEWAY_API_VERSION ?= v1.7.0
TRAEFIK_CHART_VERSION ?= 42.3.2
INGRESS_NGINX_CHART_VERSION ?= 4.15.1
# Namespace of the releases of make test-install, with the external PostgreSQL
# and ZEO servers of the scenarios that use them.
CI_NAMESPACE ?= plone-ci
# make test-upgrade: the published version to upgrade from, the latest when
# empty, and the values of both installs.
UPGRADE_FROM ?=
UPGRADE_VALUES ?= $(CHART_DIR)/ci/default-values.yaml
UPGRADE_NAMESPACE ?= plone-upgrade

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

.PHONY: lint
lint: ## Lint the chart once per CI scenario, as CI does (needs ct, from chart-testing)
	@echo -e "$(GREEN)==> Lint the chart$(RESET)"
	@ct lint --all --chart-dirs charts --chart-repos cnpg=$(CNPG_REPO)

.PHONY: cluster-deps
cluster-deps: ## Install what the CI scenarios need in the current kubectl cluster: CloudNativePG, Gateway API, Traefik, ingress-nginx, external servers
	@echo -e "$(GREEN)==> Install the CloudNativePG operator$(RESET)"
	@helm upgrade --install cnpg cloudnative-pg --repo $(CNPG_REPO) --version $(CNPG_OPERATOR_VERSION) \
		--namespace cnpg-system --create-namespace --wait
	@echo -e "$(GREEN)==> Install the Gateway API CRDs$(RESET)"
	@kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_API_VERSION)/standard-install.yaml
	@# Traefik serves the HTTPRoute of the gateway scenarios, with the Gateway
	@# traefik-gateway of its chart, as in docs/how-to/enable-traefik-gateway-api.md.
	@# A ClusterIP Service, as kind has no load balancer: helm test reaches it
	@# from inside the cluster.
	@echo -e "$(GREEN)==> Install Traefik with its Gateway$(RESET)"
	@helm upgrade --install traefik traefik --repo https://traefik.github.io/charts --version $(TRAEFIK_CHART_VERSION) \
		--namespace traefik --create-namespace --wait \
		--set service.spec.type=ClusterIP \
		--set providers.kubernetesGateway.enabled=true \
		--set gateway.listeners.web.namespacePolicy.from=All
	@kubectl wait --for=create gateway/traefik-gateway --namespace traefik --timeout=120s
	@kubectl wait --for=condition=Programmed gateway/traefik-gateway --namespace traefik --timeout=120s
	@# The ingress-nginx controller serves the Ingress resources of the
	@# varnish-ingress-nginx scenario.
	@echo -e "$(GREEN)==> Install the ingress-nginx controller$(RESET)"
	@helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --version $(INGRESS_NGINX_CHART_VERSION) \
		--namespace ingress-nginx --create-namespace --wait \
		--set controller.service.type=ClusterIP
	@# The external PostgreSQL and ZEO servers of the external-* scenarios, in
	@# the namespace of the releases, which reach them by their Service names.
	@echo -e "$(GREEN)==> Create the external servers in the namespace $(CI_NAMESPACE)$(RESET)"
	@kubectl create namespace $(CI_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply --namespace $(CI_NAMESPACE) -f tests/cluster/external-services.yaml
	@kubectl wait --for=condition=Ready cluster/external-postgresql --namespace $(CI_NAMESPACE) --timeout=300s
	@kubectl rollout status deployment/external-zeo --namespace $(CI_NAMESPACE) --timeout=300s

.PHONY: test-install
test-install: chart-deps ## Install the chart once per CI scenario in the current kubectl cluster, and run helm test, as CI does (needs ct, and make cluster-deps)
	@echo -e "$(GREEN)==> Install the chart and run helm test$(RESET)"
	@# Helm waits for the Job that creates the Plone site, which takes a few
	@# minutes.
	@ct install --all --chart-dirs charts --chart-repos cnpg=$(CNPG_REPO) \
		--namespace $(CI_NAMESPACE) --helm-extra-args "--timeout 15m"

.PHONY: test-upgrade
test-upgrade: chart-deps ## Install the last published release, create content, upgrade to this chart, and check the content (needs make cluster-deps)
	@echo -e "$(GREEN)==> Test the upgrade from the published chart$(RESET)"
	@UPGRADE_FROM="$(UPGRADE_FROM)" UPGRADE_VALUES="$(UPGRADE_VALUES)" UPGRADE_NAMESPACE="$(UPGRADE_NAMESPACE)" \
		bash tests/upgrade.sh

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
