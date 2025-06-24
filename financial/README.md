# Financial Dataset for Symbolic Regression

This directory contains financial datasets and analysis tools for discovering latent equations in stock market data using symbolic regression techniques.

## Overview

The financial dataset includes:
- **S&P 500 (SPY)** historical data
- **Apple (AAPL)** historical data  
- Multiple prediction tasks for symbolic regression analysis

## Directory Structure

```
financial/
├── README.md                           # This file
├── download_data_robust.py            # Robust data downloader
├── generate_datasets.ipynb            # Dataset generation and feature engineering
├── evaluate_equations.ipynb           # Equation evaluation and analysis
└── csvs/                              # Data files
    ├── SPY_historical.csv             # S&P 500 historical data
    ├── AAPL_historical.csv            # Apple historical data
    ├── financial_combined.csv         # Combined dataset
    ├── financial_datasets_summary.csv # Summary of all datasets
    ├── financial_master_dataset.csv   # Master dataset for SR
    └── *_symbolic_regression.csv      # Individual prediction task datasets
```

## Features

Each dataset includes engineered features for symbolic regression:

### Basic OHLCV Data
- `Open`, `High`, `Low`, `Close`, `Volume`
- `Date`, `Symbol`

### Technical Indicators
- `Daily_Return`: Daily price returns
- `Log_Return`: Logarithmic returns
- `High_Low_Ratio`: High/Low price ratio
- `RSI`: Relative Strength Index (14-day)

### Moving Averages
- `Price_MA_5`, `Price_MA_20`: 5-day and 20-day price moving averages
- `Volume_MA_5`, `Volume_MA_20`: 5-day and 20-day volume moving averages

### Volatility Measures
- `Volatility_5`, `Volatility_20`: 5-day and 20-day rolling volatility

### Momentum & Volume
- `Price_Change_5d`, `Price_Change_20d`: Multi-day price changes
- `Volume_Ratio`: Current volume / 20-day average volume

### Calendar Features
- `DayOfWeek`, `Month`, `Year`: Time-based features

## Prediction Tasks

The dataset includes multiple symbolic regression tasks:

1. **Next-day Return Prediction** (`*_next_day_return`)
   - Target: Tomorrow's daily return
   - Use: Short-term price movement prediction

2. **5-day Return Prediction** (`*_5day_return`)
   - Target: 5-day ahead returns
   - Use: Medium-term price movement prediction

3. **Volatility Prediction** (`*_volatility`)
   - Target: Future 5-day volatility
   - Use: Risk/uncertainty prediction

4. **Price Direction** (`*_direction`)
   - Target: Binary (up=1, down=0)
   - Use: Classification of price movements

## Usage

### 1. Data Download
```bash
python download_data_robust.py
```
This script will attempt to download real financial data. If the download fails due to network restrictions, it will generate realistic sample data for demonstration.

### 2. Dataset Generation
Open and run `generate_datasets.ipynb` to:
- Process raw financial data
- Engineer features for symbolic regression  
- Create multiple prediction tasks
- Generate summary statistics

### 3. Equation Evaluation
Open and run `evaluate_equations.ipynb` to:
- Test various financial equation hypotheses
- Fit equations using curve fitting
- Compare performance across different models
- Analyze cross-asset behavior

## Equation Hypotheses Tested

Based on financial theory, the following equation forms are evaluated:

1. **Mean Reversion**: `return = c1 * (price - moving_average) + c2`
2. **Momentum**: `return = c1 * volatility + c2 * RSI + c3`  
3. **Volume-Price**: `return = c1 * log(volume_ratio) + c2 * price_range + c3`
4. **Technical Analysis**: Multi-indicator combinations
5. **Complex Multi-factor**: Interactions between factors

## Integration with LibraryAugmentedSymbolicRegression.jl

To use this dataset with the main symbolic regression framework:

1. The datasets are saved in CSV format compatible with the framework
2. Use `financial_master_dataset.csv` for comprehensive analysis
3. Individual task datasets (`*_symbolic_regression.csv`) for focused analysis

### Example Integration

Add a "Financial" case to the main dataset selection in `experiments/main.py`:

```python
case "Financial":
    # Load financial dataset
    dataset_path = "financial/csvs/financial_master_dataset.csv"
    # Configure for financial analysis
```

## Key Insights

Financial markets present unique challenges for symbolic regression:

- **High Noise**: Financial returns have low signal-to-noise ratios
- **Non-stationarity**: Market regimes change over time
- **Non-linearity**: Complex interactions between factors
- **External Factors**: News, sentiment, macroeconomic events

## Data Quality Notes

- Sample data is generated using realistic market dynamics if real data download fails
- Features are engineered to capture common financial relationships
- All datasets include proper handling of missing values and outliers
- Time series structure is preserved for temporal analysis

## Future Extensions

Potential enhancements to the financial dataset:

1. **Additional Assets**: More stocks, bonds, commodities
2. **Higher Frequency**: Intraday data (minutes, hours)
3. **Alternative Data**: Sentiment, news, social media
4. **Macroeconomic**: Interest rates, inflation, GDP
5. **Options Data**: Implied volatility, Greeks
6. **Cross-Asset**: Correlations, sector effects

## References

- Yahoo Finance API (yfinance library)
- Financial technical analysis indicators
- Market microstructure research
- Behavioral finance theories