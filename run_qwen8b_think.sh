export SILICON_FLOW_MODEL="deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
export SILICON_FLOW_MODEL_URL="https://api.siliconflow.cn/v1"
export SILICON_FLOW_API_KEY="siliconflow.key"

# [INFO] Synthetic Datasets
NUM_SAMPLES=500

# [INFO] Synthetic Datasets for Qwen3-8B-thinking 1e-4 C_Prompt & Parser
python -m experiments.main --llm_recorder_dir "lasr_runs_synthetic_llama32" \
    --use_llm --use_prompt_evol \
    --model $SILICON_FLOW_MODEL --api_key $SILICON_FLOW_API_KEY \
    --model_url $SILICON_FLOW_MODEL_URL \
    --exp_idx 12 --dataset_path data/synthetic_equations.csv  \
    --dataset "Synthetic" \
    --hints_path data/synthetic_hints.json --prompts_path prompts/C_improved_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
    --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints