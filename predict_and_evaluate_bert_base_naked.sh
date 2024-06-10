#!/bin/bash -l
#SBATCH --job-name="nlp-project-predict-and-evaluate-after-ft-bert-base-naked"
#SBATCH --time=24:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=gpu # set the partition to gpu
#SBATCH --gres=gpu:tesla:1 # assign a single tesla gpu
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm/slurm_%x.%j.out # STDOUT

# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3
module load cudnn/7.6.5.32-10.1

source activate tapas_clean_env

export PYTHONPATH=$(pwd):$PYTHONPATH

OUTPUT_DIR="ft_result_tableformer_base_naked"
INIT_CHECKPOINT="${OUTPUT_DIR}/wtq/model"
BERT_CONFIG_FILE="${INIT_CHECKPOINT}/bert_config.json"

python tapas/run_task_main.py \
  --task="WTQ" \
  --tapas_verbosity=DEBUG \
  --train_batch_size=32 \
  --output_dir="${OUTPUT_DIR}" \
  --init_checkpoint="${INIT_CHECKPOINT}" \
  --bert_config_file="${BERT_CONFIG_FILE}" \
  --mode="predict_and_evaluate"
