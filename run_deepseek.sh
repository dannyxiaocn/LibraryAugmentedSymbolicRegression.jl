# export OPENROUTER_MODEL="deepseek/deepseek-chat-v3-0324:free"
# export OPENROUTER_MODEL_URL="https://openrouter.ai/api/v1"
# export OPENROUTER_API_KEY="openrouter.key"

# export SILICON_FLOW_MODEL="Qwen/Qwen3-8B"
export SILICON_FLOW_MODEL="deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
export SILICON_FLOW_MODEL_URL="https://api.siliconflow.cn/v1"
export SILICON_FLOW_API_KEY="siliconflow.key"

# [INFO] DeepSeek V3
# export DEEPSEEK_MODEL="deepseek-chat"
export DEEPSEEK_MODEL="deepseek-reasoner"
export DEEPSEEK_MODEL_URL="https://api.deepseek.com"
export DEEPSEEK_API_KEY="deepseek.key"

# [INFO] Synthetic Datasets
NUM_SAMPLES=500

# [INFO] Synthetic Datasets for Qwen3-8B
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $SILICON_FLOW_MODEL --api_key $SILICON_FLOW_API_KEY --model_url $SILICON_FLOW_MODEL_URL \
    --exp_idx 4 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints

# [INFO] Synthetic Datasets for DeepSeek R1 8B
# python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
#     --use_llm --use_prompt_evol \
#     --model $SILICON_FLOW_MODEL --api_key $SILICON_FLOW_API_KEY --model_url $SILICON_FLOW_MODEL_URL \
#     --exp_idx 5 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
#     --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
#     --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
#     --start_idx 0 --end_idx 11 --use_hints

# [INFO] Synthetic Datasets for DeepSeek V3
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY --model_url $DEEPSEEK_MODEL_URL \
    --exp_idx 6 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints

# [INFO] Synthetic Datasets for DeepSeek R1
# python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 7 --dataset_path data/synthetic_equations.csv  --dataset "Synthetic" \
#     --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
#     --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
#     --start_idx 4 --end_idx 11 --use_hints

# # [INFO] Feynman Equations
# python -m experiments.main --llm_recorder_dir "lasr_runs_deepseek_v3_0324" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 3 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" \
#     --start_idx 0 \
#     --hints_path data/feynman_hints.json \
#     --prompts_path prompts/ \
#     --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 --llm_gen_random_weight 1e-4 \
#     --num_iterations 10 --early_stopping_condition 1e-5 --num_samples 5