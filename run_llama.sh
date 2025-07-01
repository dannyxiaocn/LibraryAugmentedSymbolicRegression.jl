export OLLAMA_MODEL="llama3.2"
export OLLAMA_MODEL_URL="http://localhost:11434/v1"
export OLLAMA_API_KEY="ollama.key"

echo "Model URL: $OLLAMA_MODEL_URL"
echo "API Key: $OLLAMA_API_KEY"

NUM_SAMPLES=500

# [INFO] LaSR llama3.2 synthetic with base prompts
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 0 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/base_prompts/ \
    --llm_crossover_weight 1e-5 --llm_mutate_weight 1e-5 --llm_gen_random_weight 1e-5 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11

# [INFO] LaSR llama3.2 synthetic with llama3.2 prompts
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 1 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
    --llm_crossover_weight 1e-5 --llm_mutate_weight 1e-5 --llm_gen_random_weight 1e-5 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11

# [INFO] LaSR llama3.2 synthetic with hints
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 2 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
    --llm_crossover_weight 1e-5 --llm_mutate_weight 1e-5 --llm_gen_random_weight 1e-5 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints

# [INFO] LaSR llama3.2 synthetic with hints and more crossover and mutation weights
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 3 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints


# [INFO] LaSR llama3.2 synthetic with C_improved_prompts
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 9 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/C_improved_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
    --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints