export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

# Cross-platform realpath from 
# https://stackoverflow.com/a/18443300
# NOTE: Adapted for Makefile use
define BASH_FUNC_realpath%%
() {
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
}
endef
export BASH_FUNC_realpath%%

define echo_debug
	echo -e "\033[0;37m[DBG]:\033[0m" ${1}
endef
define echo_info
	echo -e "[INF]:" ${1}
endef
define echo_warn
	echo -e "\033[0;33m[WRN]:\033[0m" ${1}
endef
define echo_error
	echo -e "\033[0;31m[ERR]:\033[0m" ${1}
endef

export echo_debug
export echo_info
export echo_warn
export echo_error

define mkdir_cleanup_on_error
	function tearDown {
		rm -rf ${1}
	}
	trap tearDown ERR
	mkdir -p ${1}
endef

export mkdir_cleanup_on_error

.ONESHELL:

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

define run_dataset_normalization
	@RAW_PATH="${ROOT_DIR}/${1}/${2}"
	@NORM_PATH="${ROOT_DIR}/$(subst raw,normalized,${1})/${3}"
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	@$(call echo_debug,"  - Normalizing $$(find "$${RAW_PATH}" -type f | wc -l) ${3} files...")
	mkdir -p "$${NORM_PATH}"
	docker run -it --rm \
		-v "$${RAW_PATH}":/mnt/inputs \
		-v "$${NORM_PATH}":/mnt/outputs \
		"$${IMAGE_NAME}"
	$(call echo_debug,"    + Done!")
endef

export run_dataset_normalization

.DEFAULT_GOAL := help

.PHONY: help
help: ## This help.
	@grep -E \
		'^[\/\.0-9a-zA-Z_-]+:.*?## .*$$' \
		$(MAKEFILE_LIST) \
		| grep -v '<!PRIVATE>' \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		       {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: submodules
.SILENT: submodules
submodules: ## Ensures that submodules are setup.
	## https://stackoverflow.com/a/52407662
	if git submodule status | egrep -q '^[-]|^[+]' ; then \
		echo_debug "Need to reinitialize git submodules"; \
		git submodule update --init; \
	fi

datasets/raw/code2seq/java-small: ## Download code2seq's Java small dataset (non-preprocessed sources) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'raw/code2seq/java-small'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-tar.sh" \
		https://s3.amazonaws.com/code2seq/datasets/java-small.tar.gz \
		"${ROOT_DIR}/datasets/raw/code2seq"
	@$(call echo_debug,"  + Download complete!")

datasets/raw/code2seq/java-med: ## Downloads code2seq's Java medium dataset (non-preprocessed sources) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'raw/code2seq/java-med'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-tar.sh" \
		https://s3.amazonaws.com/code2seq/datasets/java-med.tar.gz \
		"${ROOT_DIR}/datasets/raw/code2seq"
	@$(call echo_debug,"  + Download complete!")

datasets/raw/code-search-net/java: ## Downloads CodeSearchNet's Java data (GitHub's code search dataset) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'raw/code-search-net/java'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-zip.sh" \
		https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/java.zip \
		"${ROOT_DIR}/datasets/raw/code-search-net" \
		"java/final/jsonl/*"
	@$(call echo_debug,"  + Download complete!")

datasets/raw/code-search-net/python: ## Downloads CodeSearchNet's Python data (GitHub's code search dataset) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'raw/code-search-net/python'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-zip.sh" \
		https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/python.zip \
		"${ROOT_DIR}/datasets/raw/code-search-net" \
		"python/final/jsonl/*"
	@$(call echo_debug,"  + Download complete!")

.PHONY: download-datasets
download-datasets: submodules | datasets/raw/code2seq/java-small datasets/raw/code2seq/java-med datasets/raw/code-search-net/java datasets/raw/code-search-net/python ## Downloads all prerequisite datasets
	@$(call echo_info,"Downloaded all datasets to './datasets/raw/' directory.")

.PHONY: build-normalizer
build-normalizer: submodules ## Builds our dataset normalizer docker image
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	@IMAGE_CONTEXT="$(shell mktemp -d)"
	@$(call echo_debug,"Building '$${IMAGE_NAME}'...")
	@$(call mkdir_cleanup_on_error,$${IMAGE_CONTEXT})
	mkdir -p "$${IMAGE_CONTEXT}/vendor"
	cp -r "${ROOT_DIR}/tasks/normalize-raw-dataset" "$${IMAGE_CONTEXT}"
	cp -r "${ROOT_DIR}/vendor/CodeSearchNet/function_parser" "$${IMAGE_CONTEXT}/vendor/function_parser"
	docker build \
		-t "$${IMAGE_NAME}" \
		-f "${ROOT_DIR}/tasks/normalize-raw-dataset/Dockerfile" \
		"$${IMAGE_CONTEXT}" | sed "s/^/$$(printf "\r\033[37m[DBG]:\033[0m ")/"
	@rm -rf $${IMAGE_CONTEXT}
	@$(call echo_debug,"  + Image built!")

datasets/normalized/code2seq/java-small: ## Generate a normalized version of code2seq's Java small dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/code2seq/java-small'...")
	@$(call mkdir_cleanup_on_error,$@)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-small,training,train)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-small,validation,valid)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-small,test,test)
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/code2seq/java-med: ## Generate a normalized version of code2seq's Java med dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/code2seq/java-med'...")
	@$(call mkdir_cleanup_on_error,$@)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-med,training,train)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-med,validation,valid)
	@$(call run_dataset_normalization,datasets/raw/code2seq/java-med,test,test)
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/code-search-net/java: ## Generates a normalized version of CodeSearchNet's Java dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/code-search-net/java'...")
	@$(call mkdir_cleanup_on_error,$@)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/java,train,train)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/java,valid,valid)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/java,test,test)
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/code-search-net/python: ## Generates a normalized version of CodeSearchNet's Python dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/code-search-net/python'...")
	@$(call mkdir_cleanup_on_error,$@)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/python,train,train)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/python,valid,valid)
	@$(call run_dataset_normalization,datasets/raw/code-search-net/python,test,test)
	@$(call echo_debug,"  + Normalization complete!")

.PHONY: normalize-datasets
normalize-datasets: submodules build-normalizer | datasets/normalized/code2seq/java-small datasets/normalized/code2seq/java-med datasets/normalized/code-search-net/java datasets/normalized/code-search-net/python ## Normalizes all downloaded datasets
	@$(call echo_info,"Normalized all datasets to './datasets/normalized/' directory.")
