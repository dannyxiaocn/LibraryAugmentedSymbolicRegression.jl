import re
import numpy as np
import matplotlib.pyplot as plt
import os
from collections import defaultdict

def extract_loss_from_summary(file_path):
    """Extract loss values for each equation from a summary file."""
    losses = {}
    
    if not os.path.exists(file_path):
        print(f"Warning: File {file_path} does not exist")
        return losses
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find all equation sections
    equation_sections = re.findall(r'GT Equation #(\d+):.*?Score: ([\d.e-]+), Loss: ([\d.e-]+)', content, re.DOTALL)
    
    for eq_num, score, loss in equation_sections:
        eq_num = int(eq_num)
        loss = float(loss)
        losses[eq_num] = loss
        print(f"Exp file {file_path}: Equation {eq_num}, Loss: {loss}")
    
    return losses

def main():
    # Initialize data structure
    exp_data = {}
    base_path = "lasr_runs_synthetic_llama32"
    
    # Extract data from all 8 experiments
    for exp_num in range(8):
        exp_path = f"{base_path}/exp_{exp_num}/summary.txt"
        print(f"\nProcessing {exp_path}")
        losses = extract_loss_from_summary(exp_path)
        exp_data[exp_num] = losses
    
    # Determine which equations are present across experiments
    all_equations = set()
    for exp_losses in exp_data.values():
        all_equations.update(exp_losses.keys())
    
    all_equations = sorted(list(all_equations))
    print(f"\nEquations found: {all_equations}")
    
    # Create plots
    n_equations = len(all_equations)
    fig, axes = plt.subplots(2, 5, figsize=(20, 10))
    axes = axes.flatten()
    
    experiments = list(range(8))
    
    for i, eq_num in enumerate(all_equations):
        ax = axes[i]
        
        # Collect loss values for this equation across all experiments
        losses_for_eq = []
        exp_labels = []
        
        for exp_num in experiments:
            if eq_num in exp_data[exp_num]:
                losses_for_eq.append(exp_data[exp_num][eq_num])
                exp_labels.append(f"Exp {exp_num}")
            else:
                # If equation is missing in this experiment, skip it
                pass
        
        if losses_for_eq:
            # Use log scale for better visualization since loss values vary widely
            log_losses = np.log10(np.array(losses_for_eq))
            
            bars = ax.bar(range(len(losses_for_eq)), log_losses, alpha=0.7)
            ax.set_xlabel('Experiment')
            ax.set_ylabel('Log10(Loss)')
            ax.set_title(f'Equation #{eq_num} Loss Comparison')
            ax.set_xticks(range(len(exp_labels)))
            ax.set_xticklabels(exp_labels, rotation=45)
            
            # Add actual loss values as text on bars
            for j, (bar, loss) in enumerate(zip(bars, losses_for_eq)):
                height = bar.get_height()
                ax.text(bar.get_x() + bar.get_width()/2., height + 0.05,
                       f'{loss:.2e}', ha='center', va='bottom', fontsize=8, rotation=45)
            
            ax.grid(True, alpha=0.3)
        else:
            ax.text(0.5, 0.5, 'No data', transform=ax.transAxes, 
                   ha='center', va='center', fontsize=12)
            ax.set_title(f'Equation #{eq_num} - No Data')
    
    # Hide unused subplots
    for i in range(n_equations, len(axes)):
        axes[i].set_visible(False)
    
    plt.tight_layout()
    plt.savefig('loss_comparison_plots/loss_comparison_all_equations.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Create a summary table
    print("\n" + "="*80)
    print("LOSS COMPARISON SUMMARY TABLE")
    print("="*80)
    
    # Print header
    header = "Equation"
    for exp_num in experiments:
        header += f"\tExp {exp_num}"
    print(header)
    print("-" * 80)
    
    # Print data for each equation
    for eq_num in all_equations:
        row = f"Eq #{eq_num}"
        for exp_num in experiments:
            if eq_num in exp_data[exp_num]:
                loss = exp_data[exp_num][eq_num]
                row += f"\t{loss:.2e}"
            else:
                row += f"\t-"
        print(row)
    
    # Also create individual plots for each equation with better readability
    for eq_num in all_equations:
        plt.figure(figsize=(12, 6))
        
        losses_for_eq = []
        exp_labels = []
        colors = []
        
        for exp_num in experiments:
            if eq_num in exp_data[exp_num]:
                losses_for_eq.append(exp_data[exp_num][eq_num])
                exp_labels.append(f"Exp {exp_num}")
                colors.append(f'C{exp_num}')
        
        if losses_for_eq:
            bars = plt.bar(exp_labels, losses_for_eq, color=colors, alpha=0.7, edgecolor='black')
            plt.yscale('log')
            plt.xlabel('Experiment')
            plt.ylabel('Loss (log scale)')
            plt.title(f'Loss Comparison - Equation #{eq_num}')
            plt.grid(True, alpha=0.3)
            
            # Add loss values as text on bars
            for bar, loss in zip(bars, losses_for_eq):
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height * 1.1,
                        f'{loss:.2e}', ha='center', va='bottom', fontsize=10, rotation=45)
            
            plt.tight_layout()
            plt.savefig(f'loss_comparison_plots/equation_{eq_num}_loss_comparison.png', dpi=300, bbox_inches='tight')
            plt.show()

if __name__ == "__main__":
    main() 