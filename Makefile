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

datasets/code2seq/java-small: ## Download code2seq's Java small dataset (non-preprocessed sources) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'code2seq/java-small'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-tar.sh" \
		https://s3.amazonaws.com/code2seq/datasets/java-small.tar.gz \
		"${ROOT_DIR}/datasets/code2seq"
	@$(call echo_debug,"  + Download complete!")

datasets/code2seq/java-med: ## Downloads code2seq's Java medium dataset (non-preprocessed sources) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'code2seq/java-medium'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-tar.sh" \
		https://s3.amazonaws.com/code2seq/datasets/java-med.tar.gz \
		"${ROOT_DIR}/datasets/code2seq"
	@$(call echo_debug,"  + Download complete!")

datasets/code-search-net/java: ## Downloads CodeSearchNet's Java data (GitHub's code search dataset) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'code-search-net/java'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-zip.sh" \
		https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/java.zip \
		"${ROOT_DIR}/datasets/code-search-net" \
		"java/final/jsonl/*"
	@$(call echo_debug,"  + Download complete!")

datasets/code-search-net/python: ## Downloads CodeSearchNet's Python data (GitHub's code search dataset) <!PRIVATE>
	@$(call echo_debug,"Downloading dataset 'code-search-net/python'...")
	@$(call mkdir_cleanup_on_error,$@)
	"${ROOT_DIR}/scripts/download-zip.sh" \
		https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/python.zip \
		"${ROOT_DIR}/datasets/code-search-net" \
		"python/final/jsonl/*"
	@$(call echo_debug,"  + Download complete!")

download-datasets: submodules | datasets/code2seq/java-small datasets/code2seq/java-med datasets/code-search-net/java datasets/code-search-net/python ## Downloads all prerequisite datasets
	@$(call echo_info,"Downloaded all datasets to './datasets/' directory.")

