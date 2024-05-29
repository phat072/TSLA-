# Load necessary libraries
library(tidyverse)
library(TTR)
library(lubridate)
library(ggplot2)

# Read the data
df <- read_csv('TSLA.csv')

# Set the date as the index
df <- df %>% mutate(Date = ymd(Date)) %>% arrange(Date)

# Create a function to calculate the simple moving average 
SMA <- function(data, period = 30, column = 'Close') {
  return(SMA(data[[column]], n=period))
}

# Build and show the data set
df <- df %>% mutate(
  SMA = SMA(df, 21),
  Simple_Returns = lag(Close / lag(Close) - 1),
  Log_Returns = log(1 + Simple_Returns),
  Ratios = Close / SMA
)

# Get and show the percentile values
percentiles <- c(15, 20, 50, 80, 85)
Ratios <- df$Ratios %>% drop_na()
Percentile_values <- quantile(Ratios, percentiles / 100)

# Create the buy and sell signals for the strategy
Sell <- Percentile_values['85%'] # The 85th percentile threshold where we want to sell
Buy <- Percentile_values['15%'] # The 15th percentile threshold where we want to buy

df <- df %>% mutate(
  Positions = ifelse(Ratios > Sell, -1, ifelse(Ratios < Buy, 1, NA)),
  Positions = fill(Positions, .direction = "down"),
  Buy = ifelse(Positions == 1, Close, NA),
  Sell = ifelse(Positions == -1, Close, NA)
)

# Calculate the returns for the Mean Reversion Strategy
df <- df %>% mutate(
  Strategy_returns = lag(Positions) * Log_Returns
)

# Print the returns for both strategies
print(paste('Buy & Hold Strategy Returns: ', exp(cumsum(df$Log_Returns, na.rm = TRUE))[[length(df$Log_Returns)]] - 1))
print(paste('Mean Reversion Strategy Returns: ', exp(cumsum(df$Strategy_returns, na.rm = TRUE))[[length(df$Strategy_returns)]] - 1))