#!/bin/bash -l
#SBATCH --job-name="NLP Project"
#SBATCH --time=08:00:00 # set an appropriate amount of time for the job to run here in HH:MM:SS format
#SBATCH --partition=main # set the partition to gpu
#SBATCH --cpus-per-task=1
#SBATCH --output=/gpfs/space/home/ploter/projects/tapas/slurm_%x.%j.out # STDOUT

# Here you need to run train.py with python from the virtual environment where you have all the dependencies install
# You also have to pass the command line args (such as dataset name) to the script here, as well
# You may use whichever virtual environment manager you prefer (conda, venv, etc.)

module load miniconda3

source activate tapas_clean_env

python tapas/run_task_main.py \
--task="WTQ" \
--input_dir="WikiTableQuestions" \
--output_dir="WikiTableQuestionsOutput" \
--bert_vocab_file="tapas_model/vocab.txt" \
--mode="create_data"