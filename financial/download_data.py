#!/usr/bin/env python3
"""
Download financial data for S&P 500 index and Apple stock.
This script downloads historical data and processes it for symbolic regression analysis.
"""

import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

def download_financial_data():
    """Download S&P 500 and Apple stock data"""
    
    # Define symbols
    symbols = {
        'SPY': 'S&P 500 ETF (proxy for S&P 500 index)',  # SPY is the most liquid S&P 500 ETF
        'AAPL': 'Apple Inc.'
    }
    
    # Download 5 years of data
    end_date = datetime.now()
    start_date = end_date - timedelta(days=5*365)
    
    data = {}
    
    for symbol, description in symbols.items():
        print(f"Downloading {description} ({symbol})...")
        
        # Download data
        ticker = yf.Ticker(symbol)
        df = ticker.history(start=start_date, end=end_date, interval='1d')
        
        if df.empty:
            print(f"Warning: No data downloaded for {symbol}")
            continue
            
        # Reset index to make Date a column
        df = df.reset_index()
        
        # Add symbol column
        df['Symbol'] = symbol
        
        # Calculate additional features for symbolic regression
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
        
        # Store the data
        data[symbol] = df
        
        # Save individual CSV
        csv_path = f'csvs/{symbol}_historical.csv'
        df.to_csv(csv_path, index=False)
        print(f"Saved {len(df)} rows to {csv_path}")
    
    # Combine all data into one DataFrame
    if data:
        combined_df = pd.concat(data.values(), ignore_index=True)
        combined_df.to_csv('csvs/financial_combined.csv', index=False)
        print(f"Saved combined data with {len(combined_df)} rows to csvs/financial_combined.csv")
        
        # Create a summary
        print("\nData Summary:")
        for symbol in data.keys():
            symbol_data = combined_df[combined_df['Symbol'] == symbol]
            print(f"{symbol}: {len(symbol_data)} days, "
                  f"from {symbol_data['Date'].min()} to {symbol_data['Date'].max()}")
    
    return data

if __name__ == "__main__":
    # Change to financial directory
    os.chdir('/Users/xiaobocheng/final_project/LibraryAugmentedSymbolicRegression.jl/financial')
    
    try:
        data = download_financial_data()
        print("Financial data download completed successfully!")
    except ImportError:
        print("yfinance library not found. Please install it with:")
        print("pip install yfinance")
    except Exception as e:
        print(f"Error downloading financial data: {e}")