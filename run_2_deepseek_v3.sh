# [INFO] DeepSeek V3
export DEEPSEEK_MODEL="deepseek-chat"
# export DEEPSEEK_MODEL="deepseek-reasoner"
export DEEPSEEK_MODEL_URL="https://api.deepseek.com"
export DEEPSEEK_API_KEY="deepseek.key"

# [INFO] Synthetic Datasets
NUM_SAMPLES=500


# [INFO] Syn2 Datasets for DeepSeek V3
# python -m experiments.main --llm_recorder_dir "lasr_syn2" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
#     --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 3 --dataset_path data/syn2_equations.csv  \
#     --dataset "Syn2" \
#     --hints_path data/syn2_hints.json \
#     --prompts_path prompts/C_improved_prompts/ \
#     --llm_crossover_weight 1e-4 --llm_mutate_weight 1e-4 \
#     --llm_gen_random_weight 1e-4 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES \
#     --early_stopping_condition 1e-5 \
#     --start_idx 0 --end_idx 11 --use_hints

# [INFO] Syn2D Datasets for DeepSeek V3 1e-3 parser_improved_prompts
# python -m experiments.main --llm_recorder_dir "lasr_syn2" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
#     --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 8 --dataset_path data/syn2_equations.csv  \
#     --dataset "Syn2D" \
#     --hints_path data/syn2_hints.json \
#     --prompts_path prompts/parser_improved_prompts/ \
#     --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
#     --llm_gen_random_weight 1e-3 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES \
#     --early_stopping_condition 1e-5 \
#     --start_idx 0 --end_idx 11 --use_hints

# [INFO] Syn2I Datasets for DeepSeek V3 1e-3 40 iterations
python -m experiments.main --llm_recorder_dir "lasr_syn2" \
    --use_llm --use_prompt_evol \
    --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
    --model_url $DEEPSEEK_MODEL_URL \
    --exp_idx 10 --dataset_path data/syn2_equations.csv  \
    --dataset "Syn2I" \
    --hints_path data/syn2_hints.json \
    --prompts_path prompts/parser_improved_prompts/ \
    --llm_crossover_weight 1e-3 --llm_mutate_weight 1e-3 \
    --llm_gen_random_weight 1e-3 \
    --num_iterations 40  --num_samples $NUM_SAMPLES \
    --early_stopping_condition 1e-5 \
    --start_idx 0 --end_idx 11 --use_hints

# [INFO] Syn2D2 Datasets for DeepSeek V3 1e-2 parser_improved_prompts
# python -m experiments.main --llm_recorder_dir "lasr_syn2" \
#     --use_llm --use_prompt_evol \
#     --model $DEEPSEEK_MODEL --api_key $DEEPSEEK_API_KEY \
#     --model_url $DEEPSEEK_MODEL_URL \
#     --exp_idx 11 --dataset_path data/syn2_equations.csv  \
#     --dataset "Syn2D2" \
#     --hints_path data/syn2_hints.json \
#     --prompts_path prompts/parser_improved_prompts/ \
#     --llm_crossover_weight 1e-2 --llm_mutate_weight 1e-2 \
#     --llm_gen_random_weight 1e-2 \
#     --num_iterations 10  --num_samples $NUM_SAMPLES \
#     --early_stopping_condition 1e-5 \
#     --start_idx 0 --end_idx 11 --use_hints