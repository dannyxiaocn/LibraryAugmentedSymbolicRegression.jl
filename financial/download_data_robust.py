#!/usr/bin/env python3
"""
Robust financial data downloader with multiple fallback methods.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os
import requests
import time

def download_via_yfinance():
    """Try downloading via yfinance"""
    try:
        import yfinance as yf
        
        # Define symbols
        symbols = ['SPY', 'AAPL']
        
        # Download 5 years of data (shorter period to avoid issues)
        end_date = datetime.now()
        start_date = end_date - timedelta(days=5*365)
        
        data = {}
        
        for symbol in symbols:
            print(f"Downloading {symbol} via yfinance...")
            
            try:
                # Download data with different parameters
                ticker = yf.Ticker(symbol)
                df = ticker.history(start=start_date, end=end_date, period="5y", interval='1d')
                
                if not df.empty:
                    data[symbol] = df
                    print(f"Successfully downloaded {len(df)} rows for {symbol}")
                else:
                    print(f"No data returned for {symbol}")
                    
            except Exception as e:
                print(f"Failed to download {symbol}: {e}")
                continue
        
        return data
        
    except ImportError:
        print("yfinance not available")
        return {}
    except Exception as e:
        print(f"yfinance method failed: {e}")
        return {}

def create_sample_data():
    """Create sample financial data for demonstration purposes"""
    print("Creating sample financial data...")
    
    # Generate 500 days of sample data
    dates = pd.date_range(start='2022-01-01', periods=500, freq='D')
    
    # Sample S&P 500 data (starting around 4000)
    np.random.seed(42)  # For reproducibility
    spy_prices = []
    current_price = 4000
    
    for i in range(len(dates)):
        # Simple random walk with slight upward trend
        daily_return = np.random.normal(0.0005, 0.012)  # ~0.05% daily return, 1.2% volatility
        current_price *= (1 + daily_return)
        spy_prices.append(current_price)
    
    spy_data = pd.DataFrame({
        'Date': dates,
        'Open': [p * np.random.uniform(0.995, 1.005) for p in spy_prices],
        'Close': spy_prices,
        'Symbol': 'SPY'
    })
    
    # Add High and Low
    spy_data['High'] = [max(o, c) * np.random.uniform(1.001, 1.01) for o, c in zip(spy_data['Open'], spy_data['Close'])]
    spy_data['Low'] = [min(o, c) * np.random.uniform(0.99, 0.999) for o, c in zip(spy_data['Open'], spy_data['Close'])]
    spy_data['Volume'] = np.random.randint(50000000, 200000000, len(dates))
    
    # Sample Apple data (starting around 150)
    np.random.seed(43)
    aapl_prices = []
    current_price = 150
    
    for i in range(len(dates)):
        # Apple tends to be more volatile
        daily_return = np.random.normal(0.0008, 0.02)  # Higher volatility
        current_price *= (1 + daily_return)
        aapl_prices.append(current_price)
    
    aapl_data = pd.DataFrame({
        'Date': dates,
        'Open': [p * np.random.uniform(0.99, 1.01) for p in aapl_prices],
        'Close': aapl_prices,
        'Symbol': 'AAPL'
    })
    
    # Add High and Low
    aapl_data['High'] = [max(o, c) * np.random.uniform(1.002, 1.015) for o, c in zip(aapl_data['Open'], aapl_data['Close'])]
    aapl_data['Low'] = [min(o, c) * np.random.uniform(0.985, 0.998) for o, c in zip(aapl_data['Open'], aapl_data['Close'])]
    aapl_data['Volume'] = np.random.randint(30000000, 150000000, len(dates))
    
    return {'SPY': spy_data, 'AAPL': aapl_data}

def add_features(df):
    """Add features for symbolic regression"""
    
    # Calculate additional features
    df['Daily_Return'] = df['Close'].pct_change()
    df['Log_Return'] = np.log(df['Close'] / df['Close'].shift(1))
    df['High_Low_Ratio'] = df['High'] / df['Low']
    df['Volume_MA_5'] = df['Volume'].rolling(5).mean()
    df['Volume_MA_20'] = df['Volume'].rolling(20).mean()
    df['Price_MA_5'] = df['Close'].rolling(5).mean()
    df['Price_MA_20'] = df['Close'].rolling(20).mean()
    df['Volatility_5'] = df['Daily_Return'].rolling(5).std()
    df['Volatility_20'] = df['Daily_Return'].rolling(20).std()
    
    # RSI calculation (simplified version)
    delta = df['Close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(14).mean()
    rs = gain / loss
    df['RSI'] = 100 - (100 / (1 + rs))
    
    # Add day of week, month features
    df['DayOfWeek'] = df['Date'].dt.dayofweek
    df['Month'] = df['Date'].dt.month
    df['Year'] = df['Date'].dt.year
    
    # Price momentum features
    df['Price_Change_5d'] = df['Close'] / df['Close'].shift(5) - 1
    df['Price_Change_20d'] = df['Close'] / df['Close'].shift(20) - 1
    
    # Volume features
    df['Volume_Ratio'] = df['Volume'] / df['Volume_MA_20']
    
    return df

def main():
    """Main function to download and process financial data"""
    
    # Change to financial directory
    os.chdir('/Users/xiaobocheng/final_project/LibraryAugmentedSymbolicRegression.jl/financial')
    
    # Try downloading real data first
    data = download_via_yfinance()
    
    # If real data download fails, use sample data
    if not data:
        print("Real data download failed, creating sample data for demonstration...")
        data = create_sample_data()
    
    if not data:
        print("No data available!")
        return
    
    # Process each dataset
    processed_data = {}
    for symbol, df in data.items():
        print(f"Processing {symbol}...")
        
        # Reset index if needed
        if 'Date' not in df.columns and df.index.name == 'Date':
            df = df.reset_index()
        
        # Add features
        df = add_features(df)
        
        # Remove rows with NaN values
        df = df.dropna()
        
        processed_data[symbol] = df
        
        # Save individual CSV
        csv_path = f'csvs/{symbol}_historical.csv'
        df.to_csv(csv_path, index=False)
        print(f"Saved {len(df)} rows to {csv_path}")
    
    # Combine all data
    if processed_data:
        combined_df = pd.concat(processed_data.values(), ignore_index=True)
        combined_df.to_csv('csvs/financial_combined.csv', index=False)
        print(f"Saved combined data with {len(combined_df)} rows to csvs/financial_combined.csv")
        
        # Create summary
        print("\nData Summary:")
        print(f"Columns: {list(combined_df.columns)}")
        for symbol in processed_data.keys():
            symbol_data = combined_df[combined_df['Symbol'] == symbol]
            print(f"{symbol}: {len(symbol_data)} days, "
                  f"from {symbol_data['Date'].min()} to {symbol_data['Date'].max()}")
            print(f"  Average daily return: {symbol_data['Daily_Return'].mean():.4f}")
            print(f"  Volatility: {symbol_data['Daily_Return'].std():.4f}")

if __name__ == "__main__":
    main()