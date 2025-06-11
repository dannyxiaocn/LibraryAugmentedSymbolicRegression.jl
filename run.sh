# idx 0 = LaSR Feynman runs with p=0.10
# idx 1 = LaSR Synthetic runs with p=0.01
# idx 2 = LaSR Feynman runs with p=0.01 gpt-3.5-turbo-0125
# idx 3 = Ablation experiments with no variables.
# idx 4 = Ablation experiments with no concept evolution (No concepts at all)
# idx 5 = Ablation experiments with no concept crossover (Concepts aren't refined)
# idx 6 = Ablation experiments with hints
# idx 7 = LaSR Feynman run with 400 iterations.
export OLLAMA_MODEL_URL="http://localhost:11434/v1"
export OLLAMA_API_KEY="ollama.key"

# export VLLM_MODEL="meta-llama/Meta-Llama-3.1-8B-Instruct"
# export VLLM_MODEL_URL="https://avior.mlfoundry.com/live-inference/v1"
# export VLLM_API_KEY="foundry_api.key"

echo "Model URL: $OLLAMA_MODEL_URL"
echo "API Key: $OLLAMA_API_KEY"

# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm --use_prompt_evol --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 0 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --prompts_path prompts/ --llm_crossover_weight 0.10 --llm_mutate_weight 0.10 --llm_gen_random_weight 0.10
# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm --use_prompt_evol --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 1 --dataset_path data/FeynmanEquations.csv  --dataset "Synthetic" --hints_path data/feynman_hints.json --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01
# # python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm --use_prompt_evol --model "gpt-3.5-turbo-0125" --api_key api.key --model_url https://api.openai.com/v1 --exp_idx 2 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01
# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm --use_prompt_evol --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 3 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --early_stopping_condition 1e-5 --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01 --ablation_mode no-variables
# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm                   --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 4 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --early_stopping_condition 1e-5 --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01 --ablation_mode no-concepts
# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm                   --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 5 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --early_stopping_condition 1e-5 --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01 --ablation_mode no-crossover --disable_prompt_concepts
# python -m experiments.main --llm_recorder_dir "lasr_reruns" --use_llm --use_prompt_evol --model $VLLM_MODEL --api_key $VLLM_API_KEY --model_url $VLLM_MODEL_URL --exp_idx 6 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" --hints_path data/feynman_hints.json --early_stopping_condition 1e-5 --prompts_path prompts/ --llm_crossover_weight 0.01 --llm_mutate_weight 0.01 --llm_gen_random_weight 0.01 --use_hints

# [INFO] LaSR llama3.1:8b
# python -m experiments.main --llm_recorder_dir "lasr_runs" \
#     --use_llm --use_prompt_evol \
#     --model "llama3.1:8b" --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
#     --exp_idx 1 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" \
#     --hints_path data/feynman_hints.json --prompts_path prompts/ \
#     --llm_crossover_weight 0.0001 --llm_mutate_weight 0.0001 --llm_gen_random_weight 0.0001 \
#     --num_iterations 40 --early_stopping_condition 1e-5

# [INFO] LaSR thinking deepseek-r1:8b
python -m experiments.main --llm_recorder_dir "lasr_thinking_runs" \
    --use_llm --use_prompt_evol \
    --model "deepseek-r1:8b" --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
    --exp_idx 1 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" \
    --hints_path data/feynman_hints.json --prompts_path prompts/ \
    --llm_crossover_weight 0.0001 --llm_mutate_weight 0.0001 --llm_gen_random_weight 0.0001 \
    --num_iterations 40 --early_stopping_condition 1e-5

# [INFO] PySR Baseline
# python -m experiments.main --llm_recorder_dir "pysr_baseline" \
#     --model $OLLAMA_MODEL --api_key $OLLAMA_API_KEY --model_url $OLLAMA_MODEL_URL \
#     --exp_idx 1 --dataset_path data/FeynmanEquations.csv  --dataset "Feynman" \
#     --hints_path data/feynman_hints.json --prompts_path prompts/ \
#     --llm_crossover_weight 0 --llm_mutate_weight 0 --llm_gen_random_weight 0 \
#     --num_iterations 40 --early_stopping_condition 1e-5