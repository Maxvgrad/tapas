#!/bin/bash -l
#SBATCH --job-name="nlp-project-pretrain-bert-tiny-sample"
#SBATCH --time=04:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=gpu # set the partition to gpu
#SBATCH --gres=gpu:tesla:1 # assign a single tesla gpu
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm_%x.%j.out # STDOUT

# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3
module load cudnn/7.6.5.32-10.1

source activate tapas_clean_env

export PYTHONPATH=$(pwd):$PYTHONPATH

python tapas/run_task_main.py \
  --task="WTQ" \
  --output_dir="results_ft_bert_tiny_sample" \
  --init_checkpoint="results_ft_bert_tiny_sample/wtq/model/model.ckpt-10.data-00000-of-00001" \
  --bert_config_file="uncased_L-2_H-128_A-2/bert_config.json" \
  --mode="train"