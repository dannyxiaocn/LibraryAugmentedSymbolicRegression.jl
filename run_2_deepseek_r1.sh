# [INFO] DeepSeek R1
# export DEEPSEEK_MODEL="deepseek-chat"
export DEEPSEEK_MODEL="deepseek-reasoner"
export DEEPSEEK_MODEL_URL="https://api.deepseek.com"
export DEEPSEEK_API_KEY="deepseek.key"

# export DEEPSEEK_MODEL="deepseek/deepseek-r1-0528"
# export DEEPSEEK_MODEL_URL="https://openrouter.ai/api/v1"
# export DEEPSEEK_API_KEY="openrouter.key"

# [INFO] Synthetic Datasets
NUM_SAMPLES=500


# [INFO] Syn2 Datasets for DeepSeek R1 1e-4 think_C_Prompt & Parser
# python -m experiments.main --llm_recorder_dir "lasr_syn2" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
#     --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 4 --dataset_path data/syn2_equations.csv  \
#     --dataset "Syn2" \
#     --hints_path data/syn2_hints.json \
#     --prompts_path prompts/think_C_improved_prompts/ \
#     --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
#     --llm_gen_random_weight 1e-4 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES \
#     --early_stopping_condition 1e-5 \
#     --max_tokens 16384 \
#     --start_idx 0 --end_idx 11 --use_hints

# [INFO] Syn2S Datasets for DeepSeek R1 1e-3 think_parser_improved_prompts
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
    --model_url $DEEPSEEK_MODEL_URL \
    --exp_idx 12 --dataset_path data/syn2_equations.csv  \
    --dataset "Syn2S" \
    --hints_path data/syn2_hints.json \
    --prompts_path prompts/think_parser_improved_prompts/ \
    --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
    --llm_gen_random_weight 1e-3 \
    --num_iterations 10  --num_samples $NUM_SAMPLES \
    --early_stopping_condition 1e-5 \
    --max_tokens 16384 \
    --start_idx 0 --end_idx 11 --use_hints