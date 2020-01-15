export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

.ONESHELL:

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

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

define mkdir_cleanup_on_error
	function tearDown {
		rm -rf ${1}
	}
	trap tearDown ERR
	mkdir -p ${1}
endef

define run_dataset_ast_paths_preprocessing
	@NORM_PATH="${ROOT_DIR}/${1}/${2}"
	@PROC_PATH="${ROOT_DIR}/$(subst normalized,preprocessed/ast-paths,${1})/${2}"
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	mkdir -p "$${PROC_PATH}"
	docker run -it --rm \
		-v "$${NORM_PATH}":/analysis/inputs/public/source-code \
		-v "$${PROC_PATH}":/analysis/output/fs/ast-paths/${3} \
		"$${IMAGE_NAME}"
	$(call echo_debug,"    + Done!")
endef

export echo_debug
export echo_info
export echo_warn
export echo_error

export mkdir_cleanup_on_error
export run_dataset_ast_paths_preprocessing

.DEFAULT_GOAL := help

.PHONY: help
help: ## (MISC) This help.
	@grep -E \
		'^[\/\.0-9a-zA-Z_-]+:.*?## .*$$' \
		$(MAKEFILE_LIST) \
		| grep -v '<!PRIVATE>' \
		| sort -t'(' -k2 \
		| awk 'BEGIN {FS = ":.*?## "}; \
		       {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: docker-cleanup
.SILENT: docker-cleanup
docker-cleanup: ## (MISC) Cleans up old and out-of-sync Docker images.
	$(call echo_debug,"Removing exited containers...")
	docker rm $(docker ps -aqf status=exited)
	$(call echo_debug,"  + Exited containers removed!")
	$(call echo_debug,"Removing dangling images...")
	docker rmi $(docker images -qf dangling=true)
	$(call echo_debug,"  + Dangling images removed!")
	"${ROOT_DIR}/scripts/sync-images.sh"

.PHONY: submodules
.SILENT: submodules
submodules: ## (MISC) Ensures that submodules are setup.
	## https://stackoverflow.com/a/52407662
	if git submodule status | egrep -q '^[-]|^[+]' ; then \
		echo -e "\033[0;37m[DBG]:\033[0m" "Need to reinitialize git submodules"; \
		git submodule update --init; \
	fi

.PHONY: build-image-train-model-code2seq
build-image-train-model-code2seq: ## Build tasks/train-model-code2seq <!PRIVATE>
	"${ROOT_DIR}/scripts/build-image.sh" \
		train-model-code2seq

.PHONY: build-image-download-c2s-dataset
build-image-download-c2s-dataset: ## Builds tasks/download-c2s-dataset <!PRIVATE>
	"${ROOT_DIR}/scripts/build-image.sh" \
		download-c2s-dataset

.PHONY: build-image-download-csn-dataset
build-image-download-csn-dataset: ## Builds tasks/download-csn-dataset <!PRIVATE>
	"${ROOT_DIR}/scripts/build-image.sh" \
		download-csn-dataset

datasets/raw/c2s/java-small: ## Download code2seq's Java small dataset (non-preprocessed sources) <!PRIVATE>
	@IMAGE_NAME="$(shell whoami)/averloc--download-c2s-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/c2s/java-small:/mnt" \
		-e DATASET_URL=https://s3.amazonaws.com/code2seq/datasets/java-small.tar.gz \
		"$${IMAGE_NAME}"

datasets/raw/c2s/java-med: ## Downloads code2seq's Java medium dataset (non-preprocessed sources) <!PRIVATE>
	@IMAGE_NAME="$(shell whoami)/averloc--download-c2s-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/c2s/java-med:/mnt" \
		-e DATASET_URL=https://s3.amazonaws.com/code2seq/datasets/java-med.tar.gz \
		"$${IMAGE_NAME}"

datasets/raw/csn/java: ## Downloads CodeSearchNet's Java data (GitHub's code search dataset) <!PRIVATE>
	@IMAGE_NAME="$(shell whoami)/averloc--download-csn-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/csn/java:/mnt" \
		-e DATASET_URL=https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/java.zip \
		"$${IMAGE_NAME}"

datasets/raw/csn/python: ## Downloads CodeSearchNet's Python data (GitHub's code search dataset) <!PRIVATE>
	@IMAGE_NAME="$(shell whoami)/averloc--download-csn-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/csn/python:/mnt" \
		-e DATASET_URL=https://s3.amazonaws.com/code-search-net/CodeSearchNet/v2/python.zip \
		"$${IMAGE_NAME}"

.PHONY: download-datasets
download-datasets: submodules build-image-download-csn-dataset build-image-download-c2s-dataset | datasets/raw/c2s/java-small datasets/raw/c2s/java-med datasets/raw/csn/java datasets/raw/csn/python ## (DS-1) Downloads all prerequisite datasets
	@$(call echo_info,"Downloaded all datasets to './datasets/raw/' directory.")

.PHONY: build-image-normalize-raw-dataset
build-image-normalize-raw-dataset: submodules ## Builds our dataset normalizer docker image  <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		normalize-raw-dataset

datasets/normalized/c2s/java-small: ## Generate a normalized version of code2seq's Java small dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/c2s/java-small'...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/outputs" \
		"$${IMAGE_NAME}" java gz
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/c2s/java-med: ## Generate a normalized version of code2seq's Java med dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/c2s/java-med'...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/c2s/java-med:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-med:/mnt/outputs" \
		"$${IMAGE_NAME}" java gz
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/csn/java: ## Generates a normalized version of CodeSearchNet's Java dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/csn/java'...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/csn/java:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/normalized/csn/java:/mnt/outputs" \
		"$${IMAGE_NAME}" java gz
	@$(call echo_debug,"  + Normalization complete!")

datasets/normalized/csn/python: ## Generates a normalized version of CodeSearchNet's Python dataset <!PRIVATE>
	@$(call echo_debug,"Normalizing dataset 'raw/csn/python'...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/raw/csn/python:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/normalized/csn/python:/mnt/outputs" \
		"$${IMAGE_NAME}" python gz
	@$(call echo_debug,"  + Normalization complete!")

.PHONY: debug-normalize
debug-normalize:
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	docker run -it --rm \
	  -v "${ROOT_DIR}/vendor/CodeSearchNet/function_parser/function_parser:/src/function-parser/function_parser" \
		-v "${ROOT_DIR}/datasets/raw/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/debug:/mnt/outputs" \
		"$${IMAGE_NAME}" java gz

.PHONY: normalize-datasets
normalize-datasets: submodules build-image-normalize-raw-dataset | datasets/normalized/c2s/java-small datasets/normalized/c2s/java-med datasets/normalized/csn/java datasets/normalized/csn/python ## (DS-2) Normalizes all downloaded datasets
	@$(call echo_info,"Normalized all datasets to './datasets/normalized/' directory.")

.PHONY: build-image-preprocess-dataset-c2s
build-image-preprocess-dataset-c2s: submodules ## Builds a preprocessor for generating code2seq style data <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		preprocess-dataset-c2s

datasets/preprocessed/ast-paths/c2s/java-small: ## Generate a preprocessed (representation: ast-paths) version of code2seq's Java small dataset (step 2/2) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/ast-paths/c2s/java-small' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths/c2s/java-small:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/preprocessed/ast-paths/c2s/java-med: ## Generate a preprocessed (representation: ast-paths) version of code2seq's Java med dataset (step 2/2) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/ast-paths/c2s/java-med' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-med:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths/c2s/java-med:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/preprocessed/ast-paths/csn/java: ## Generate a preprocessed (representation: ast-paths) version of CodeSearchNet's Java dataset (step 2/2) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/ast-paths/csn/java' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/csn/java:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths/csn/java:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

extract-ast-paths: submodules build-image-preprocess-dataset-c2s | datasets/preprocessed/ast-paths/c2s/java-small datasets/preprocessed/ast-paths/c2s/java-med datasets/preprocessed/ast-paths/csn/java ## (DS-3) Generate preprocessed data in a form usable by code2seq style models. 
	@$(call echo_info,"AST Paths (code2seq style) preprocessed representations extracted!")

.PHONY: check-dataset-name
check-dataset-name:
ifndef DATASET_NAME
	$(error DATASET_NAME is a required parameter for this target.)
endif

.PHONY: train-model-code2seq
test-model-code2seq: check-dataset-name build-image-train-model-code2seq ## (DEBUG) Trains the code2seq model on the Java Small dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--train-model-code2seq:$(shell git rev-parse HEAD)"
	DOCKER_API_VERSION=1.40 docker run -it --rm \
		-v "${ROOT_DIR}/models:/models" \
		-v "${ROOT_DIR}/$${DATASET_NAME}:/mnt/inputs" \
		"$${IMAGE_NAME}"

.PHONY: danger-clear-ast-paths-java-small
danger-clear-ast-paths-java-small: ## Clears out the datasets/preprocessed/ast-paths/c2s/java-small directory (and its staging dir). <!PRIVATE>
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths:/mnt" \
		debian:9 \
			rm -rf /mnt/_staging/c2s/java-small /mnt/c2s/java-small

.PHONY: build-image-spoon-apply-transforms
build-image-spoon-apply-transforms: ## Builds our dockerized version of spoon. <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		spoon-apply-transforms

.PHONY: test-spoon-transforms
test-spoon-transforms: build-image-spoon-apply-transforms ## Test spoon.
	@IMAGE_NAME="$(shell whoami)/averloc--spoon-apply-transforms:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small:/mnt/outputs" \
	  -v "${ROOT_DIR}/vendor/CodeSearchNet/function_parser/function_parser:/src/function-parser/function_parser" \
		--entrypoint bash \
		"$${IMAGE_NAME}"

.PHONY: normalize-c2s-transformed
normalize-c2s-transformed: build-image-normalize-raw-dataset
	@$(call echo_debug,"Normalizing dataset 'transformed/raw/c2s/java-small'...")
	@IMAGE_NAME="$(shell whoami)/averloc--normalize-raw-dataset:$(shell git rev-parse HEAD)"
	for trans in ${ROOT_DIR}/datasets/transformed/raw/c2s/java-small/*; do
		mkdir -p "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/$$(basename $$trans)"
		docker run -it --rm \
			-v "${ROOT_DIR}/datasets/transformed/raw/c2s/java-small/$$(basename $$trans):/mnt/inputs" \
			-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/$$(basename $$trans):/mnt/outputs" \
			"$${IMAGE_NAME}"
	done;
	@$(call echo_debug,"  + Normalization complete!")
