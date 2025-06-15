# export OPENROUTER_MODEL="deepseek/deepseek-chat-v3-0324:free"
# export OPENROUTER_MODEL_URL="https://openrouter.ai/api/v1"
# export OPENROUTER_API_KEY="openrouter.key"

# [INFO] DeepSeek V3
export DEEPSEEK_MODEL="deepseek-chat"
export DEEPSEEK_MODEL_URL="https://api.deepseek.com"
export DEEPSEEK_API_KEY="deepseek.key"

# [INFO] DeepSeek R1
# export DEEPSEEK_MODEL="deepseek-reasoner"
# export DEEPSEEK_MODEL_URL="https://api.deepseek.com"
# export DEEPSEEK_API_KEY="deepseek.key"

# [INFO] Synthetic Datasets
python -m experiments.main --llm_recorder_dir "lasr_runs_deepseek_v3_0324_synthetic" \
    --use_llm --use_prompt_evol \
    --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY --model_url $DEEPSEEK_MODEL_URL \
    --exp_idx 0 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --start_idx 0 \
    --hints_path data/synthetic_hints.json \
    --prompts_path prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
    --num_iterations 10 --early_stopping_condition 1e-5 --num_samples 5

# [INFO] Feynman Equations
python -m experiments.main --llm_recorder_dir "lasr_runs_deepseek_v3_0324" \
    --use_llm --use_prompt_evol \
    --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY --model_url $DEEPSEEK_MODEL_URL \
    --exp_idx 3 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" \
    --start_idx 0 \
    --hints_path data/feynman_hints.json \
    --prompts_path prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
    --num_iterations 10 --early_stopping_condition 1e-5 --num_samples 5