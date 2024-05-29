# Load necessary libraries
library(tidyverse)
library(lubridate)
library(TTR)

# Read the data
df <- read.csv('TSLA.csv')

# Set the date as the index
df$Date <- as.Date(df$Date)
df <- df %>% arrange(Date)

# Calculate the simple moving average 
df$SMA <- SMA(df$Close, n=21)

# Calculate simple and log returns
df$Simple_Returns <- c(0, diff(df$Close) / df$Close[-length(df$Close)])
df$Log_Returns <- log(1 + df$Simple_Returns)

# Calculate ratios
df$Ratios <- df$Close / df$SMA

# Get and show the percentile values
percentiles <- c(15, 20, 50, 80, 85)
Percentile_values <- quantile(df$Ratios, probs = percentiles/100, na.rm = TRUE)

# Create the buy and sell signals for the strategy
Sell <- Percentile_values['85%'] # The 85th percentile threshold where we want to sell
Buy <- Percentile_values['15%'] # The 15th percentile threshold where we want to buy

# Put -1 where the ratio is greater than the percentile to sell and NA otherwise
df$Positions <- ifelse(df$Ratios > Sell, -1, NA)

# Put 1 where the ratio is less than the percentile to buy and put the current value otherwise
df$Positions <- ifelse(df$Ratios < Buy, 1, df$Positions)

# Use na.locf from zoo package to fill the missing values in the data frame. na.locf stands for last observation carried forward
df$Positions <- zoo::na.locf(df$Positions, na.rm=FALSE)

# Get the buy and sell signals
df$Buy <- ifelse(df$Positions == 1, df$Close, NA)
df$Sell <- ifelse(df$Positions == -1, df$Close, NA)

# Calculate the returns for the Mean Reversion Strategy
df$Strategy_returns <- lag(df$Positions, default=0) * df$Log_Returns

# Print the returns for both strategies
print(paste('Buy & Hold Strategy Returns: ', exp(sum(df$Log_Returns, na.rm=TRUE)) - 1))
print(paste('Mean Reversion Strategy Returns: ', exp(sum(df$Strategy_returns, na.rm=TRUE)) - 1))