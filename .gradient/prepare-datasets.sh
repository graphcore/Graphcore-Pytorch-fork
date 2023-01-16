#!/bin/bash

symlink-public-resources() {
    # This function will "symlink" one read only folder and make it appear
    # as read write in the target directory. This is used to make gradient
    # datasets appear in directories with read/write permissions.

    public_source_dir=${1}
    target_dir=${2}
    # need to wait until the dataset has been mounted (async on Paperspace's end)
    MAX_MOUNT_TIME=60
    WAITING_FOR=0
    # while [ ! -d ${public_source_dir} ] && [ "$((${WAITING_FOR}<${MAX_MOUNT_TIME}))" -eq 1 ]
    # do
    #     echo "Waiting for dataset "${public_source_dir}" to be mounted..."
    #     sleep 1
    # done
    # To use an overlay mount in a container we need to make sure that the
    # work and upper directories are not themselves in overlays.
    OVERLAY_DIRECTORY="/fusedoverlay"
    if [ ! -d ${OVERLAY_DIRECTORY} ]; then
        echo "Mounting new tmpfs to ${OVERLAY_DIRECTORY}"
        mkdir -p /fusedoverlay
        mount -t tmpfs tmpfs ${OVERLAY_DIRECTORY}
    fi
    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    mkdir -p ${public_source_dir}
    mkdir -p ${target_dir}
    workdir="${OVERLAY_DIRECTORY}/workdirs/${public_source_dir}"
    upperdir="${OVERLAY_DIRECTORY}/upperdir/${public_source_dir}"
    mkdir -p ${workdir}
    mkdir -p ${upperdir}
    mount -t overlay overlay -o lowerdir=${public_source_dir},upperdir=${upperdir},workdir=${workdir} ${target_dir}

}


echo "Starting preparation of datasets"
# symlink exe_cache files
exe_cache_source_dir="${PUBLIC_DATASET_DIR}/poplar-executables-pytorch-3-1"
symlink-public-resources "${exe_cache_source_dir}" $POPLAR_EXECUTABLE_CACHE_DIR
# Symlink squad
symlink-public-resources "${PUBLIC_DATASET_DIR}/squad" "${HF_DATASETS_CACHE}/squad"
# Symlink OGB Wiki dataset and checkpoint
symlink-public-resources "${PUBLIC_DATASET_DIR}/ogbl_wikikg2_custom" "${DATASET_DIR}/ogbl_wikikg2_custom"

# symlink local dataset used by vit-model-training notebook
# symlink-public-resources "${PUBLIC_DATASET_DIR}/chest-xray-nihcc" "${DATASET_DIR}/chest-xray-nihcc"

# pre-install the correct version of optimum for this release
python -m pip install "optimum-graphcore>=0.5, <0.6"

echo "Finished running setup.sh."
# Run automated test if specified
if [[ "$1" == "test" ]]; then
    #source .gradient/automated-test.sh "${@:2}"
    bash /notebooks/.gradient/automated-test.sh $2 $3 $4 $5 $6 $7 $8
elif [[ "$2" == "test" ]]; then
    #source .gradient/automated-test.sh "${@:2}"
    bash /notebooks/.gradient/automated-test.sh $3 $4 $5 $6 $7 $8 $9
fi
