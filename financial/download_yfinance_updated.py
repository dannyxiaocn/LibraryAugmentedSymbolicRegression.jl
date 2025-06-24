#!/usr/bin/env python3
"""
Updated yfinance downloader based on official documentation
"""

import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

def download_with_yfinance():
    """Download data using updated yfinance methods"""
    
    # Create tickers
    spy = yf.Ticker("SPY")
    aapl = yf.Ticker("AAPL")
    
    # Download data - try different methods
    print("Method 1: Using history() with period")
    try:
        spy_data = spy.history(period="2y")
        aapl_data = aapl.history(period="2y")
        print(f"SPY: {len(spy_data)} rows, AAPL: {len(aapl_data)} rows")
        if not spy_data.empty and not aapl_data.empty:
            return {'SPY': spy_data, 'AAPL': aapl_data}
    except Exception as e:
        print(f"Method 1 failed: {e}")
    
    print("Method 2: Using history() with start/end dates")
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=730)  # 2 years
        
        spy_data = spy.history(start=start_date, end=end_date)
        aapl_data = aapl.history(start=start_date, end=end_date)
        print(f"SPY: {len(spy_data)} rows, AAPL: {len(aapl_data)} rows")
        if not spy_data.empty and not aapl_data.empty:
            return {'SPY': spy_data, 'AAPL': aapl_data}
    except Exception as e:
        print(f"Method 2 failed: {e}")
    
    print("Method 3: Using download() function")
    try:
        data = yf.download(['SPY', 'AAPL'], period="2y", group_by='ticker')
        if not data.empty:
            spy_data = data['SPY'].dropna()
            aapl_data = data['AAPL'].dropna()
            print(f"SPY: {len(spy_data)} rows, AAPL: {len(aapl_data)} rows")
            if not spy_data.empty and not aapl_data.empty:
                return {'SPY': spy_data, 'AAPL': aapl_data}
    except Exception as e:
        print(f"Method 3 failed: {e}")
    
    print("Method 4: Single ticker download")
    try:
        spy_data = yf.download('SPY', period="2y")
        aapl_data = yf.download('AAPL', period="2y")
        print(f"SPY: {len(spy_data)} rows, AAPL: {len(aapl_data)} rows")
        if not spy_data.empty and not aapl_data.empty:
            return {'SPY': spy_data, 'AAPL': aapl_data}
    except Exception as e:
        print(f"Method 4 failed: {e}")
    
    return None

def add_features(df, symbol):
    """Add features for symbolic regression"""
    
    # Reset index to make Date a column
    df = df.reset_index()
    df['Symbol'] = symbol
    
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
    
    # RSI calculation
    delta = df['Close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(14).mean()
    rs = gain / loss
    df['RSI'] = 100 - (100 / (1 + rs))
    
    # Add calendar features
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
    """Main function"""
    os.chdir('/Users/xiaobocheng/final_project/LibraryAugmentedSymbolicRegression.jl/financial')
    
    print("yfinance version:", yf.__version__)
    print("Attempting to download financial data...")
    
    # Try to download data
    data = download_with_yfinance()
    
    if data is None:
        print("All download methods failed. Using existing sample data.")
        return
    
    # Process data
    processed_data = {}
    for symbol, df in data.items():
        print(f"Processing {symbol}...")
        df = add_features(df, symbol)
        df = df.dropna()  # Remove NaN values
        processed_data[symbol] = df
        
        # Save individual CSV
        csv_path = f'csvs/{symbol}_historical.csv'
        df.to_csv(csv_path, index=False)
        print(f"Saved {len(df)} rows to {csv_path}")
    
    # Combine data
    if processed_data:
        combined_df = pd.concat(processed_data.values(), ignore_index=True)
        combined_df.to_csv('csvs/financial_combined.csv', index=False)
        print(f"Saved combined data with {len(combined_df)} rows")
        
        # Summary
        print("\nData Summary:")
        for symbol in processed_data.keys():
            symbol_data = combined_df[combined_df['Symbol'] == symbol]
            print(f"{symbol}: {len(symbol_data)} days, "
                  f"from {symbol_data['Date'].min()} to {symbol_data['Date'].max()}")

if __name__ == "__main__":
    main()