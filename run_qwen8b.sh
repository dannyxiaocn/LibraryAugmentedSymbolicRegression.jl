export SILICON_FLOW_MODEL="Qwen/Qwen3-8B"
export SILICON_FLOW_MODEL_URL="https://api.siliconflow.cn/v1"
export SILICON_FLOW_API_KEY="siliconflow.key"

# [INFO] Synthetic Datasets
NUM_SAMPLES=500

# [INFO] Synthetic Datasets for Qwen3-8B 1e-3
# python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
#     --use_llm --use_prompt_evol \
#     --model $SILICON_FLOW_MODEL --api_key $SILICON_FLOW_API_KEY \
#     --model_url $SILICON_FLOW_MODEL_URL \
#     --exp_idx 9 --dataset_path data/synthetic_equations.csv  \
#     --dataset "Synthetic_Difficult" \
#     --hints_path data/synthetic_hints.json --prompts_path prompts/llama32_prompts/ \
#     --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
#     --llm_gen_random_weight 1e-3 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
#     --start_idx 0 --end_idx 11 --use_hints

# [INFO] Synthetic Datasets for Qwen3-8B C_prompts 1e-4
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $SILICON_FLOW_MODEL --api_key $SILICON_FLOW_API_KEY \
    --model_url $SILICON_FLOW_MODEL_URL \
    --exp_idx 11 --dataset_path data/synthetic_equations.csv  \
    --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/C_improved_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
    --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints