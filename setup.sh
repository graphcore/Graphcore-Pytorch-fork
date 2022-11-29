#!/bin/bash
# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
# Script to be sourced on launch of the Gradient Notebook

symlink_public_resources() {
    public_source_dir=${1}
    target_dir=${2}
    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    # Make sure it exists otherwise you'll copy your current dir
    mkdir -p ${public_source_dir}
    cd ${public_source_dir}
    find -type d -exec mkdir -p "${target_dir}/{}" \;
    find -type f -not -name "*.lock" -exec cp -sP "${PWD}/{}" "${target_dir}/{}" \;
    cd -
}

copy_public_resources() {
    public_source_dir=${1}
    target_dir=${2}
    echo "Copying - ${public_source_dir} to ${target_dir}"

    # Make sure it exists otherwise you'll copy your current dir
    mkdir -p ${public_source_dir}
    cd ${public_source_dir}
    find -type d -exec mkdir -p "${target_dir}/{}" \;
    find -type f -exec rm -f "${target_dir}/{}" \;
    find -type f -not -name "*.lock" -exec cp "${PWD}/{}" "${target_dir}/{}" \;
    cd -
}

# Discover system sizes
export NUM_AVAILABLE_IPU=4
export GRAPHCORE_POD_TYPE="pod4"
# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# source "${SCRIPT_DIR}/pod-config.sh" # don't need this as we're setting the env vars explicitly above

# Cache directories
export POPLAR_EXECUTABLE_CACHE_DIR="/tmp/exe_cache"
export DATASET_DIR="/tmp/datasets"
export CHECKPOINT_DIR="/tmp/checkpoints"
export HUGGINGFACE_HUB_CACHE="/tmp/huggingface_caches"
export TRANSFORMERS_CACHE="/tmp/huggingface_caches/checkpoints"
export HF_DATASETS_CACHE="/tmp/huggingface_caches/datasets"

# Paperspace Datasets are mounted in the /datasets directory (includes poplar executables)

# symlink the poplar executables
poplar_executables_source_dir="/datasets/poplar-executables-pytorch"
symlink_public_resources $poplar_executables_source_dir $POPLAR_EXECUTABLE_CACHE_DIR &

# symlink mounted datasets
for dataset in /datasets/*; do
    # don't symlink the poplar executables, that's handled above
    test "$dataset" = "$poplar_executables_source_dir" && continue 
    # symlink the actual datasets
    symlink_public_resources $dataset $DATASET_DIR &
done

# symlink-public-resources $public_dataset_dir "/tmp/"
# copy-public-resources "${public_dataset_dir}/huggingface_caches/checkpoints" "/tmp/huggingface_caches/checkpoints"
# copy-public-resources "${public_dataset_dir}/checkpoints" "/tmp/checkpoints"

# Set framework specific variables
export TF_POPLAR_FLAGS='--executable_cache_path='${POPLAR_EXECUTABLE_CACHE_DIR}''
export POPTORCH_CACHE_DIR="${POPLAR_EXECUTABLE_CACHE_DIR}"
# pre-install the correct version of optimum for this release
python -m pip install "optimum-graphcore>0.4, <0.5"

