#!/bin/bash -l
#SBATCH --job-name="nlp-project-train-bert-tiny-5pp"
#SBATCH --time=24:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=gpu # set the partition to gpu
#SBATCH --gres=gpu:tesla:1 # assign a single tesla gpu
#SBATCH --mem=4096
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm/slurm_%x.%j.out # STDOUT

# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3
module load cudnn/7.6.5.32-10.1

source activate tapas_clean_env

export PYTHONPATH=$(pwd):$PYTHONPATH

python tapas/experiments/tapas_classifier_experiment.py \
  --input_file_train="ft_results_bert_tiny_5pp_reduced/wtq/tf_examples/random-split-1-train.tfrecord" \
  --input_file_eval="ft_results_bert_tiny_5pp_reduced/wtq/tf_examples/random-split-1-dev.tfrecord" \
  --input_file_predict="ft_results_bert_tiny_5pp_reduced/wtq/tf_examples/test.tfrecord" \
  --eval_interactions_file="ft_results_bert_tiny_5pp_reduced/wtq/interactions/random-split-1-dev.tfrecord" \
  --predict_interactions_file="ft_results_bert_tiny_5pp_reduced/wtq/interactions/test.tfrecord" \
  --prediction_output_dir="ft_results_bert_tiny_5pp_reduced/wtq/prediction_output_dir" \
  --model_dir="ft_results_bert_tiny_5pp_reduced/wtq/model" \
  --init_checkpoint="pretrain_results_bert_tiny_5pp_reduced/wtq/model/" \
  --bert_config_file="uncased_L-2_H-128_A-2/bert_config.json" \
  --compression_type="GZIP" \
  --num_aggregation_labels=4 \
  --restrict_attention_mode=table_attention \
  --attention_bias_use_relative_scalar_only \
  --attention_bias_disabled=0 \
  --num_classification_labels=0 \
  --use_answer_as_supervision=True \
  --answer_loss_importance=1.0 \
  --grad_clipping=10.0 \
  --num_train_examples=25600000 \
  --train_batch_size=512 \
  --answer_loss_cutoff=0.664694 \
  --cell_select_pref=0.207951 \
  --huber_loss_delta=0.121194 \
  --init_cell_selection_weights_to_zero=True \
  --learning_rate=0.0000193581 \
  --select_one_column=True \
  --allow_empty_column_selection=False \
  --temperature=0.0352513 \
  --warmup_ratio=0.128960 \
  --do_train