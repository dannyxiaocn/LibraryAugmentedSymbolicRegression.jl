export OLLAMA_MODEL="llama3.2"
export OLLAMA_MODEL_URL="http://localhost:11434/v1"
export OLLAMA_API_KEY="ollama.key"

NUM_SAMPLES=500

# [INFO] PySR Baseline feynman: 0 - 10
python -m experiments.main --llm_recorder_dir "pysr_feynman" \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 0 --dataset_path data/FeynmanEquations.csv \
    --dataset "Feynman" \
    --hints_path data/feynman_hints.json --prompts_path prompts/ \
    --llm_crossover_weight 0 --llm_mutate_weight 0 --llm_gen_random_weight 0 \
    --num_iterations 10 --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11