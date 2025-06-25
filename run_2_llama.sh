export OLLAMA_MODEL="llama3.2"
export OLLAMA_MODEL_URL="http://localhost:11434/v1"
export OLLAMA_API_KEY="ollama.key"

NUM_SAMPLES=500

# [INFO] LaSR llama3.2 syn2 1e-4, C_improved_prompts
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY \
    --model_url $OLLAMA_MODEL_URL \
    --exp_idx 0 --dataset_path data/syn2_equations.csv  --dataset "Syn2" \
    --hints_path data/syn2_hints.json \
    --prompts_path prompts/C_improved_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
    --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES \
    --early_stopping_condition 1e-5 \
    --start_idx 10 --end_idx 11