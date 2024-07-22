#!/bin/bash -l
#SBATCH --job-name="nlp-project-create-pretrain-examples-bert-tiny"
#SBATCH --time=36:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=main # set the partition to gpu
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=16G
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm/slurm_%x.%j.out # STDOUT
#SBATCH --mail-user=maksim.ploter@ut.ee
#SBATCH --mail-type=NONE,BEGIN,END,FAIL,REQUEUE,INVALID_DEPEND,TIME_LIMIT,TIME_LIMIT_80,TIME_LIMIT_90,TIME_LIMIT_50,ARRAY_TASKS,ALL


# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3

source activate tapas_clean_env

export PYTHONPATH=$(pwd):$PYTHONPATH

# NB! BERT Tiny
python tapas/create_pretrain_examples_main.py \
  --input_file="interactions_10pp_first.txtpb.gz" \
  --output_dir="pretrain_10pp" \
  --vocab_file="uncased_L-2_H-128_A-2/vocab.txt" \
  --runner_type="DIRECT"
