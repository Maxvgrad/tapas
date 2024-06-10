#!/bin/bash

# Ensure that the script exits if any command fails
set -e

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <results_path>"
    exit 1
fi

# Assign script arguments to variables
results_path=$1
#model_path=$2
#checkpoint=$3

# Create directories
mkdir -p "${results_path}/wtq/tf_examples"
mkdir -p "${results_path}/wtq/model"

cp -r WikiTableQuestionsOutput/wtq/* "${results_path}/wtq/"

# Write to the checkpoint file
#echo "model_checkpoint_path: \"model.ckpt-${checkpoint}\"" > "${results_path}/wtq/model/checkpoint"

# Copy the files with the specified suffixes
#for suffix in .data-00000-of-00001 .index .meta; do
#  cp "${model_path}/model.ckpt-${checkpoint}${suffix}" "${results_path}/wtq/model/model.ckpt-${checkpoint}${suffix}"
#done
