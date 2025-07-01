# Experimental Analysis Summary

## Overview

This document summarizes the experimental configurations extracted from the run scripts in the LibraryAugmentedSymbolicRegression.jl project.

## Datasets

### 1. Synthetic Dataset (`data/synthetic_equations.csv`)
- **10 equations** with varying complexity
- **500 samples per equation**
- Equations:
  1. f = sin(x)*exp(-y**2/2)
  2. g = sqrt(x**2 + y**2 + z**2)
  3. h = log(1 + exp(x))/(1 + y**2)
  4. k = sin(x*y)*cos(z*w)
  5. m = exp(-(x**2 + y**2 + z**2)/(2*sigma**2))/((2*pi)*sigma**2)**(3/2)
  6. n = x*cos(log(sqrt(x**2 + y**2) + 1e-6)) + y*sin(log(sqrt(x**2 + y**2) + 1e-6))
  7. p = y/(x + 1e-6)*exp(-(x**2 + y**2)/4)
  8. q = (exp(x) - exp(-x))*(exp(y) - exp(-y))/(1 + z**2)
  9. r = (x**3 - 2*x*y + y**2)/(x**2 + y**2 + 1)
  10. s = x/(1 + exp(-y)) + z/(1 + exp(y))

### 2. Syn2 Dataset (`data/syn2_equations.csv`)
- **10 modified equations** with different bounds and complexity
- **500 samples per equation**
- Equations:
  1. f = sin(x*y)^2 * exp(-z/2) + log(1 + w)
  2. g = log(1 + exp(x)) * cos(y*z)
  3. h = sqrt(x*y) * sin(z)^2 + exp(-w) * cos(x)
  4. k = x*cos(y) + log(1 + z*w)
  5. m = exp(x/y) * sin(z) / (1 + w^2)
  6. n = (x + y)^2 * exp(-z/3) + sin(w)
  7. p = sin(x*y)^2 / (1 + exp(-z)) + log(1 + x^2)
  8. q = log(x*y + 1)^2 * cos(z) - sin(w)^2
  9. r = sqrt(exp(x) + exp(y)) * sin(z/w)^2
  10. s = x*sin(y) + z*cos(w) + exp(-v/2)

### Dataset Variants:
- **Syn2**: All equations (1-10)
- **Syn2D**: Equations {2, 3, 4, 5, 6, 7, 8, 10} (excludes 1, 9)
- **Syn2D2**: Equations {3, 4, 6, 7, 10}
- **Syn2I**: Equations {2, 4, 10}
- **Syn2S**: Equations {6, 7}
- **Synthetic_Difficult**: Difficult subset of synthetic equations

### 3. Feynman Dataset
- Physics equations from the Feynman lectures
- Variable number of samples (typically 500)

## Models Tested

Based on the run scripts:

1. **llama3.2** (via Ollama)
2. **deepseek-chat** (DeepSeek V3)
3. **deepseek-reasoner** (DeepSeek R1)
4. **deepseek-ai/DeepSeek-R1-0528-Qwen3-8B** (Qwen3-8B with reasoning)
5. **Qwen/Qwen3-8B** (base Qwen3-8B)

## Key Experimental Parameters

### LLM Weights Tested:
- 1e-5 (0.00001)
- 1e-4 (0.0001)
- 1e-3 (0.001)
- 3e-3 (0.003)
- 1e-2 (0.01)
- 0 (baseline PySR without LLM)

### Number of Iterations:
- 10 (most common)
- 20, 40, 100, 400, 1000 (for PySR baseline scaling tests)

### Prompt Strategies:
1. `prompts/base_prompts/` - Original basic prompts
2. `prompts/llama32_prompts/` - Optimized for Llama 3.2
3. `prompts/C_improved_prompts/` - Improved prompts focusing on crossover
4. `prompts/parser_improved_prompts/` - Improved parsing-focused prompts
5. `prompts/think_C_improved_prompts/` - For reasoning models with crossover focus
6. `prompts/think_parser_improved_prompts/` - For reasoning models with parsing focus

## Active Experiments Summary

From the run scripts, the following experiments are currently active (not commented out):

### Synthetic Dataset Experiments:
1. **run_qwen8b_think.sh**: Qwen3-8B-thinking with 1e-3 weight, parser_improved_prompts
2. **run_deepseek.sh**: 
   - Qwen3-8B with 1e-4 weight
   - DeepSeek V3 with 1e-4 weight

### Syn2 Dataset Experiments:
1. **run_2_llama.sh**: Llama3.2 Syn2D with 1e-3 weight, parser_improved_prompts
2. **run_2_pysr.sh**: PySR baseline with 400 and 1000 iterations
3. **run_2_deepseek_r1.sh**: DeepSeek R1 Syn2S with 1e-3 weight, think_parser_improved_prompts
4. **run_2_deepseek_v3.sh**: DeepSeek V3 Syn2I with 1e-3 weight, 40 iterations

### Feynman Dataset Experiments:
1. **run_f_deepseek_v3.sh**: DeepSeek V3 with 3e-3 weight, 40 iterations
2. **run_f_pysr.sh**: PySR baseline with 100 iterations

## Results Summary

From the available summary files:

### Best Performing Configurations:
- **Highest scores** achieved with LLM-augmented methods (scores > 10)
- **Lower complexity** solutions found with appropriate LLM weights
- **Parser-improved prompts** show better performance in recent experiments

### Key Findings:
1. LLM augmentation significantly improves symbolic regression performance
2. Different prompt strategies work better for different model types
3. Reasoning models (DeepSeek R1, Qwen3-8B-thinking) benefit from specialized prompts
4. Higher LLM weights (1e-3) perform better on difficult equation subsets
5. Baseline PySR requires significantly more iterations to achieve comparable results