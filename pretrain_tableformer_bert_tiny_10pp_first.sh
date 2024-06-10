#!/bin/bash -l
#SBATCH --job-name="nlp-project-pretrain-bert-tiny-10pp-extended"
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

# NB! BERT Tiny
python tapas/experiments/tapas_pretraining_experiment.py \
  --eval_batch_size=32 \
  --train_batch_size=32 \
  --gradient_accumulation_steps=16 \
  --num_eval_steps=100 \
  --save_checkpoints_steps=5000 \
  --num_train_examples=64000000 \
  --max_seq_length=128 \
  --compression_type="" \
  --input_file_train="pretrain_10pp/train.tfrecord" \
  --input_file_eval="pretrain_10pp/test.tfrecord" \
  --init_checkpoint="uncased_L-2_H-128_A-2/bert_model.ckpt" \
  --bert_config_file="uncased_L-2_H-128_A-2/bert_config.json" \
  --model_dir="pretrain_results_bert_tiny_10pp_extended/wtq/model" \
  --restrict_attention_mode=table_attention \
  --attention_bias_use_relative_scalar_only \
  --attention_bias_disabled=0 \
  --do_train
