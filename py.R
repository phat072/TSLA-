#!/usr/bin/env python
# coding: utf-8

# In[22]:


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
plt.style.use('fivethirtyeight')


# In[23]:


# Read the data
df = pd.read_csv('TSLA.csv')
# Set the date as the index
df = df.set_index(pd.DatetimeIndex(df['Date'].values))


# In[24]:


df.drop(['Date'], inplace = True, axis = 1)


# In[25]:


df


# In[26]:


# Create a function to calculate the simple moving average 
def SMA(data, period = 30, column = 'Close'):
    return data[column].rolling(window=period).mean()

# Build and show the data set
df['SMA'] = SMA(df, 21)
df['Simple_Returns'] = df.pct_change(1)['Close']
df['Log_Returns'] = np.log(1+df['Simple_Returns'])
df['Ratios'] = df['Close'] / df['SMA']

# Show the data
df


# In[27]:


df['Ratios'].describe()


# In[28]:


# Get and show the percentile values
percentiles = [15, 20, 50, 80, 85]
# Remove any NA value in the Ratios column and store the result in a new variables called Ratios
Ratios = df['Ratios'].dropna()
# Get the value of the percentiles
Percentile_values = np.percentile(Ratios, percentiles)
# Show the values of the percentiles
Percentile_values


# In[29]:


# Plot the ratios
plt.figure(figsize=(14,7))
plt.title('Ratios')
df['Ratios'].dropna().plot(legend = True)
plt.axhline(Percentile_values[0], c= 'green', label = '15th percentile')
plt.axhline(Percentile_values[2], c= 'yellow', label = '50th percentile')
plt.axhline(Percentile_values[-1], c= 'red', label = '85th percentile')


# In[30]:


# Create the buy and sell signals for the strategy
Sell = Percentile_values[-1] # The 85th percentile threshold where we want to sell
Buy = Percentile_values[0] # The 15th percentile threshold where we want to buy
# Put -1 where the ratio is greater than the percentile to sell and nan otherwise
df['Positions'] = np.where(df['Ratios'] > Sell, -1, np.nan)
# Put 1 where the ratio is less than the percentile to buy and put the current value otherwise
df['Positions'] = np.where(df['Ratios'] < Buy, 1, df['Positions'])
# Use ffill to fill the missing values in the data frame. ffill stands for forward fill
df['Positions'] = df['Positions'].ffill()
# Get the buy and sell signals
df['Buy'] = np.where(df['Positions'] == 1, df['Close'], np.nan)
df['Sell'] = np.where(df['Positions'] == -1, df['Close'], np.nan)


# In[31]:


# Visualize the buy and sell signals along with the close price
plt.figure(figsize=(14,7))
plt.title('Close Price w/ Buy & Sell signals')
plt.plot(df['Close'], alpha = 0.5, label = 'Close')
plt.plot(df['SMA'], alpha = 0.5, label = 'SMA')
plt.scatter(df.index, df['Buy'], color = 'green', label = 'Buy signal', marker = '^', alpha = 1)
plt.scatter(df.index, df['Sell'], color = 'red', label = 'Sell signal', marker = 'v', alpha = 1)
plt.xlabel('Date')
plt.ylabel('Close price')
plt.legend()
plt.show()


# In[32]:


# Calculate the returns for the Mean Reversion Strategy
df['Strategy_returns'] = df['Positions'].shift(1) * df['Log_Returns']
df['Strategy_returns']

# Plot the cumulative log returns & the cumulative Mean Reversion Strategy
plt.figure(figsize=(14,7))
plt.title('Growth of $1 Investment')
plt.plot(np.exp(df['Log_Returns'].dropna()).cumprod(), c = 'green', label = 'Buy/ Hold Strategy')
plt.plot(np.exp(df['Strategy_returns'].dropna()).cumprod(), c = 'blue', label = 'Mean Reversion Strategy')
plt.legend()


# In[33]:


# Print the returns for both strategies
print('Buy & Hold Strategy Returns: ', np.exp(df['Log_Returns'].dropna()).cumprod()[-1] -1)
print('Mean Reversion Strategy Returns: ', np.exp(df['Strategy_returns'].dropna()).cumprod()[-1] -1)

