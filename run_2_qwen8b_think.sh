# export QWEN_MODEL="deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
# export QWEN_MODEL_URL="https://api.siliconflow.cn/v1"
# export QWEN_API_KEY="siliconflow.key"

# export QWEN_MODEL="deepseek/deepseek-r1-0528-qwen3-8b"
# export QWEN_MODEL="deepseek/deepseek-r1-0528-qwen3-8b:free"
# export QWEN_MODEL_URL="https://openrouter.ai/api/v1"
# export QWEN_API_KEY="openrouter.key"

export QWEN_MODEL="deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
export QWEN_MODEL_URL="https://llm.chutes.ai/v1"
export QWEN_API_KEY="chutes.key"


# [INFO] Synthetic Datasets
NUM_SAMPLES=500

# [INFO] Syn2 Datasets for Qwen3-8B-thinking 1e-4 C_Prompt & Parser
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $QWEN_MODEL --api_key $QWEN_API_KEY \
    --model_url $QWEN_MODEL_URL \
    --exp_idx 2 --dataset_path data/syn2_equations.csv  --dataset "Syn2" \
    --hints_path data/syn2_hints.json --prompts_path prompts/think_C_improved_prompts/ \
    --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
    --llm_gen_random_weight 1e-4 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --max_tokens 16384 \
    --start_idx 5 --end_idx 11 --use_hints

# [INFO] Syn2D Datasets for Qwen3-8B-thinking 1e-3 parser_improved_prompts
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $QWEN_MODEL --api_key $QWEN_API_KEY \
    --model_url $QWEN_MODEL_URL \
    --exp_idx 7 --dataset_path data/syn2_equations.csv  --dataset "Syn2D" \
    --hints_path data/syn2_hints.json --prompts_path prompts/think_parser_improved_prompts/ \
    --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
    --llm_gen_random_weight 1e-3 \
    --num_iterations 10  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --max_tokens 16384 \
    --start_idx 0 --end_idx 11 --use_hints

# [INFO] Syn2I Datasets for Qwen3-8B-thinking 1e-3 parser_improved_prompts
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $QWEN_MODEL --api_key $QWEN_API_KEY \
    --model_url $QWEN_MODEL_URL \
    --exp_idx 9 --dataset_path data/syn2_equations.csv \
    --dataset "Syn2I" \
    --hints_path data/syn2_hints.json --prompts_path prompts/think_parser_improved_prompts/ \
    --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
    --llm_gen_random_weight 1e-3 \
    --num_iterations 40  --num_samples $NUM_SAMPLES --early_stopping_condition 1e-5 \
    --max_tokens 16384 \
    --start_idx 0 --end_idx 11 --use_hints