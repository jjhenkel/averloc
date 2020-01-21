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
		       {printf "\033[36m%-34s\033[0m %s\n", $$1, $$2}'

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

.PHONY: build-image-test-model-code2seq
build-image-test-model-code2seq: ## Build tasks/test-model-code2seq <!PRIVATE>
	"${ROOT_DIR}/scripts/build-image.sh" \
		test-model-code2seq

.PHONY: build-image-train-model-code2seq
build-image-train-model-code2seq: ## Build tasks/train-model-code2seq <!PRIVATE>
	"${ROOT_DIR}/scripts/build-image.sh" \
		train-model-code2seq

.PHONY: build-image-train-model-seq2seq
build-image-train-model-seq2seq: ## Build tasks/train-model-seq2seq <!PRIVATE>
	"${ROOT_DIR}/scripts/build-model-image.sh" \
		train-model-seq2seq

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
build-image-preprocess-dataset-c2s: ## Builds a preprocessor for generating code2seq style data <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		preprocess-dataset-c2s

datasets/preprocessed/ast-paths/c2s/java-small: ## Generate a preprocessed (representation: ast-paths) version of code2seq's Java small dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/ast-paths/c2s/java-small' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths/c2s/java-small:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.Identity: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.Identity' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.Identity:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameLocalVariables: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameLocalVariables' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameLocalVariables:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameLocalVariables:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.InsertPrintStatements: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.InsertPrintStatements' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.InsertPrintStatements:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.InsertPrintStatements:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameFields: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameFields' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameFields:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameFields:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameParameters: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameParameters' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameParameters:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameParameters:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ReplaceTrueFalse: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.ReplaceTrueFalse' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ReplaceTrueFalse:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ReplaceTrueFalse:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleLocalVariables: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleLocalVariables' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ShuffleLocalVariables:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleLocalVariables:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleParameters: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleParameters' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ShuffleParameters:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleParameters:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.All: ## <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/ast-paths/c2s/java-small/transforms.All' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/vendor/code2seq:/code2seq" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.All:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.All:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

extract-transformed-ast-paths: build-image-preprocess-dataset-c2s | datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.All datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleParameters datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ShuffleLocalVariables datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.ReplaceTrueFalse datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.Identity datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.InsertPrintStatements datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameLocalVariables datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameFields datasets/transformed/preprocessed/ast-paths/c2s/java-small/transforms.RenameParameters 
	@$(call echo_info,"AST Paths (code2seq style) preprocessed representations extracted (for transformed datasets)!")

datasets/preprocessed/ast-paths/c2s/java-med: ## Generate a preprocessed (representation: ast-paths) version of code2seq's Java med dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/ast-paths/c2s/java-med' (using 'ast-paths' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-c2s:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-med:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths/c2s/java-med:/mnt/outputs" \
		"$${IMAGE_NAME}" java
	@$(call echo_debug,"  + Finalizing (using 'ast-paths' representation) complete!")

datasets/preprocessed/ast-paths/csn/java: ## Generate a preprocessed (representation: ast-paths) version of CodeSearchNet's Java dataset <!PRIVATE>
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

.PHONY: build-image-preprocess-dataset-tokens
build-image-preprocess-dataset-tokens: ## Builds our tokens dataset preprocessor (for seq2seq model)  <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		preprocess-dataset-tokens

datasets/preprocessed/tokens/c2s/java-small: ## Generate a preprocessed (representation: tokens) version of code2seq's java-small dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/tokens/c2s/java-small' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/tokens/c2s/java-small:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/preprocessed/tokens/c2s/java-med: ## Generate a preprocessed (representation: tokens) version of code2seq's java-med dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/tokens/c2s/java-med' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-med:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/tokens/c2s/java-med:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/preprocessed/tokens/csn/python: ## Generate a preprocessed (representation: tokens) version of CodeSearchNet's Python dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/tokens/csn/python' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/csn/python:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/tokens/csn/python:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/preprocessed/tokens/csn/java: ## Generate a preprocessed (representation: tokens) version of CodeSearchNet's Java dataset <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'preprocessed/tokens/csn/java' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/csn/java:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/preprocessed/tokens/csn/java:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.Identity: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.Identity) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.Identity' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.Identity:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.Identity:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.InsertPrintStatements: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.InsertPrintStatements) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.InsertPrintStatements' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.InsertPrintStatements:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.InsertPrintStatements:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.All: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.All) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.All' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.All:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.All:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.ReplaceTrueFalse: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.ReplaceTrueFalse) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.ReplaceTrueFalse' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.ReplaceTrueFalse:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.ReplaceTrueFalse:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameFields: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.RenameFields) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.RenameFields' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.RenameFields:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameFields:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameParameters: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.RenameParameters) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.RenameParameters' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.RenameParameters:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameParameters:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameLocalVariables: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.RenameLocalVariables) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.RenameLocalVariables' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.RenameLocalVariables:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameLocalVariables:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleLocalVariables: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.ShuffleLocalVariables) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.ShuffleLocalVariables' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.ShuffleLocalVariables:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleLocalVariables:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleParameters: ## Generate a preprocessed (representation: tokens) version of csn's python dataset (under: transforms.ShuffleParameters) <!PRIVATE>
	@$(call echo_debug,"Finalizing dataset 'transformed/preprocessed/tokens/csn/python/transforms.ShuffleParameters' (using 'tokens' representation)...")
	@$(call mkdir_cleanup_on_error,$@)
	@IMAGE_NAME="$(shell whoami)/averloc--preprocess-dataset-tokens:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python/transforms.ShuffleParameters:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleParameters:/mnt/outputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + Finalizing (using 'tokens' representation) complete!")

.PHONY: extract-transformed-tokens-csn-python
extract-transformed-tokens-csn-python: build-image-preprocess-dataset-tokens | datasets/transformed/preprocessed/tokens/csn/python/transforms.All datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleParameters datasets/transformed/preprocessed/tokens/csn/python/transforms.ShuffleLocalVariables datasets/transformed/preprocessed/tokens/csn/python/transforms.ReplaceTrueFalse datasets/transformed/preprocessed/tokens/csn/python/transforms.Identity datasets/transformed/preprocessed/tokens/csn/python/transforms.InsertPrintStatements datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameLocalVariables datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameFields datasets/transformed/preprocessed/tokens/csn/python/transforms.RenameParameters 
	@$(call echo_info,"Tokens preprocessed representations extracted (for transformed datasets)!")

.PHONY: build-image-astor-apply-transforms
build-image-astor-apply-transforms: ## Builds our baseline generator docker image  <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		astor-apply-transforms

.PHONY: test-astor
test-astor: ## Tests our astor transformer (for python) <!PRIVATE>
	@IMAGE_NAME="$(shell whoami)/averloc--astor-apply-transforms:$(shell git rev-parse HEAD)"
	@$(call echo_debug,"Testing astor on normalized csn/python files...")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/csn/python:/mnt/inputs" \
		-v "${ROOT_DIR}/tasks/astor-apply-transforms:/app" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python:/mnt/outputs" \
		"$${IMAGE_NAME}"

.PHONY: build-image-generate-baselines
build-image-generate-baselines: ## Builds our baseline generator docker image  <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		generate-baselines

generate-baselines: build-image-generate-baselines ## (DS-5) Generate baselines (projected test sets) for our various transforms
	@IMAGE_NAME="$(shell whoami)/averloc--generate-baselines:$(shell git rev-parse HEAD)"
	@$(call echo_debug,"Generating transforms.*/baseline.jsonl.gz files...")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.All:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.All/baseline.jsonl.gz generated [1/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.InsertPrintStatements:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.InsertPrintStatements/baseline.jsonl.gz generated [2/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameFields:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.RenameFields/baseline.jsonl.gz generated [3/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameLocalVariables:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.RenameLocalVariables/baseline.jsonl.gz generated [4/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.RenameParameters:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.RenameParameters/baseline.jsonl.gz generated [5/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ReplaceTrueFalse:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.ReplaceTrueFalse/baseline.jsonl.gz generated [6/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ShuffleLocalVariables:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.ShuffleLocalVariables/baseline.jsonl.gz generated [7/8]")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.Identity:/mnt/identity" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small/transforms.ShuffleParameters:/mnt/inputs" \
		"$${IMAGE_NAME}"
	@$(call echo_debug,"  + transforms.ShuffleParameters/baseline.jsonl.gz generated [8/8]")
	@$(call echo_debug,"  + Baselines generated!")

.PHONY: check-dataset-name
check-dataset-name:
ifndef DATASET_NAME
	$(error DATASET_NAME is a required parameter for this target.)
endif

.PHONY: test-model-code2seq
test-model-code2seq: check-dataset-name build-image-test-model-code2seq ## (TEST) Tests the code2seq model on a selected dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--test-model-code2seq:$(shell git rev-parse HEAD)"
	DOCKER_API_VERSION=1.40 docker run -it --rm \
		-v "${ROOT_DIR}/models:/models" \
		-v "${ROOT_DIR}/$${DATASET_NAME}:/mnt/inputs" \
		"$${IMAGE_NAME}"

.PHONY: train-model-code2seq
train-model-code2seq: check-dataset-name build-image-train-model-code2seq ## (TRAIN) Trains the code2seq model on a selected dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--train-model-code2seq:$(shell git rev-parse HEAD)"
	DOCKER_API_VERSION=1.40 docker run -it --rm \
		-v "${ROOT_DIR}/tasks/train-model-code2seq/models:/mnt/outputs/models" \
		-v "${ROOT_DIR}/$${DATASET_NAME}:/mnt/inputs" \
		"$${IMAGE_NAME}"

.PHONY: train-model-seq2seq
train-model-seq2seq: check-dataset-name build-image-train-model-seq2seq  ## (TRAIN) Trains the seq2seq model on a selected dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--train-model-seq2seq:$(shell git rev-parse HEAD)"
	DOCKER_API_VERSION=1.40 docker run -it --rm \
		-v "${ROOT_DIR}/tasks/train-model-seq2seq/models:/mnt/outputs" \
		-v "${ROOT_DIR}/$${DATASET_NAME}:/mnt/inputs" \
		"$${IMAGE_NAME}"

.PHONY: danger-clear-ast-paths-java-small
danger-clear-ast-paths-java-small: ## Clears out the datasets/preprocessed/ast-paths/c2s/java-small directory (and its staging dir). <!PRIVATE>
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/preprocessed/ast-paths:/mnt" \
		debian:9 \
			rm -rf /mnt/_staging/c2s/java-small /mnt/c2s/java-small


.PHONY: build-image-extract-adv-dataset-tokens
build-image-extract-adv-dataset-tokens: ## Builds our adversarial dataset extractor (representation: tokens). <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		extract-adv-dataset-tokens

.PHONY: extract-adv-dataset-tokens-csn-python
extract-adv-dataset-tokens-csn-python: build-image-extract-adv-dataset-tokens
	@IMAGE_NAME="$(shell whoami)/averloc--extract-adv-dataset-tokens:$(shell git rev-parse HEAD)"
	DOCKER_API_VERSION=1.40 docker run -it --rm \
		-v "${ROOT_DIR}/datasets/transformed/preprocessed/tokens/csn/python:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/adversarial/tokens/csn/python:/mnt/outputs" \
		"$${IMAGE_NAME}" \
			transforms.RenameParameters \
			transforms.RenameFields \
			transforms.RenameLocalVariables \
			transforms.ShuffleParameters \
			transforms.ShuffleLocalVariables \
			transforms.ReplaceTrueFalse \
			transforms.InsertPrintStatements

.PHONY: build-image-spoon-apply-transforms
build-image-spoon-apply-transforms: ## Builds our dockerized version of spoon. <!PRIVATE>
	@"${ROOT_DIR}/scripts/build-image.sh" \
		spoon-apply-transforms

.PHONY: apply-transforms-c2s-java-small
apply-transforms-c2s-java-small: build-image-spoon-apply-transforms ## (DS-4) Apply our suite of transforms to code2seq's java-small dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--spoon-apply-transforms:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-e AVERLOC_JUST_TEST="$${AVERLOC_JUST_TEST}" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-small:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-small:/mnt/outputs" \
	  -v "${ROOT_DIR}/vendor/CodeSearchNet/function_parser/function_parser:/src/function-parser/function_parser" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/Transforms.java:/app/Transforms.java" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/transforms:/app/transforms" \
		"$${IMAGE_NAME}"

.PHONY: apply-transforms-c2s-java-med
apply-transforms-c2s-java-med: build-image-spoon-apply-transforms ## (DS-4) Apply our suite of transforms to code2seq's java-med dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--spoon-apply-transforms:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-e AVERLOC_JUST_TEST="$${AVERLOC_JUST_TEST}" \
		-v "${ROOT_DIR}/datasets/normalized/c2s/java-med:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/c2s/java-med:/mnt/outputs" \
	  -v "${ROOT_DIR}/vendor/CodeSearchNet/function_parser/function_parser:/src/function-parser/function_parser" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/Transforms.java:/app/Transforms.java" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/transforms:/app/transforms" \
		"$${IMAGE_NAME}"

.PHONY: apply-transforms-csn-java
apply-transforms-csn-java: build-image-spoon-apply-transforms ## (DS-4) Apply our suite of transforms to CodeSearchNet's java dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--spoon-apply-transforms:$(shell git rev-parse HEAD)"
	docker run -it --rm \
		-e AVERLOC_JUST_TEST="$${AVERLOC_JUST_TEST}" \
		-v "${ROOT_DIR}/datasets/normalized/csn/java:/mnt/inputs" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/java:/mnt/outputs" \
	  -v "${ROOT_DIR}/vendor/CodeSearchNet/function_parser/function_parser:/src/function-parser/function_parser" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/Transforms.java:/app/Transforms.java" \
		-v "${ROOT_DIR}/tasks/spoon-apply-transforms/transforms:/app/transforms" \
		"$${IMAGE_NAME}"

.PHONY: apply-transforms-csn-python
apply-transforms-csn-python: build-image-astor-apply-transforms ## (DS-4) Apply our suite of transforms to CodeSearchNet's python dataset.
	@IMAGE_NAME="$(shell whoami)/averloc--astor-apply-transforms:$(shell git rev-parse HEAD)"
	@$(call echo_debug,"Testing astor on normalized csn/python files...")
	docker run -it --rm \
		-v "${ROOT_DIR}/datasets/normalized/csn/python:/mnt/inputs" \
		-v "${ROOT_DIR}/tasks/astor-apply-transforms:/app" \
		-v "${ROOT_DIR}/datasets/transformed/normalized/csn/python:/mnt/outputs" \
		"$${IMAGE_NAME}"
