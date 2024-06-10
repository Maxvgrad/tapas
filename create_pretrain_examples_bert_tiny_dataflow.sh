#!/bin/bash -l
#SBATCH --job-name="nlp-project-create-pretrain-examples-bert-tiny-dataflow"
#SBATCH --time=08:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=main # set the partition to gpu
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm/slurm_%x.%j.out # STDOUT
#SBATCH --mail-user=maksim.ploter@gmail.com
#SBATCH --mail-type=NONE,BEGIN,END,FAIL,REQUEUE,INVALID_DEPEND,TIME_LIMIT,TIME_LIMIT_80,TIME_LIMIT_90,TIME_LIMIT_50,ARRAY_TASKS,ALL


# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3
module load cudnn/7.6.5.32-10.1

source activate tapas_pretrain_env

export PYTHONPATH=$(pwd):$PYTHONPATH

python tapas/create_pretrain_examples_main.py \
  --input_file="gs://nlp-project-tapas-pretrain-examples/interactions_10pp_first.txtpb.gz" \
  --vocab_file="gs://tapas_models/2020_05_11/vocab.txt" \
  --output_dir="gs://nlp-project-tapas-pretrain-examples/output-10pp-first" \
  --runner_type="DATAFLOW" \
  --gc_project="synthetic-diode-424805-n3" \
  --gc_region="us-central1" \
  --gc_job_name="create-pretrain-10pp-first-v2" \
  --gc_staging_location="gs://nlp-project-tapas-pretrain-examples/staging-10pp-first" \
  --gc_temp_location="gs://nlp-project-tapas-pretrain-examples/tmp-10pp-first" \
  --extra_packages=dist/tapas-table-parsing-0.0.1.dev0.tar.gz
