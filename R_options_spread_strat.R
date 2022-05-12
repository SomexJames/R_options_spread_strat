# Required Packages
require(quantmod)
require(dplyr)
require(plyr)
require(bazar)

# Retrieve stock data from specified date range
fromDate = as.Date("2000-1-1")
toDate = Sys.Date()

# List of stocks to get data from (Only works with 1 for now)
stockList = c("AAPL")

# Function that appends TA data
initialTAsetup = function(asset) {
  tempTIObj =
    merge(asset,
          RSI(Cl(asset)),
          stoch(HLC(asset)),
          SMI(HLC(asset)),
          SMA(Cl(asset), n = 100),
          all = TRUE
    )
  
  # Rename OHLC columns
  names(tempTIObj)[1:4] = c("Open","High","Low","Close")
  
  return (tempTIObj)
}

###############################################################

# For every stock in stockList, use Quantmod's getSymbols function to retrieve stock data, and append TA indicators
for (stock in stockList) {
  tempData = initialTAsetup(OHLC(
    getSymbols(
      stock,
      src = "yahoo",
      from = fromDate,
      to = toDate,
      periodicity = "daily",
      auto.assign = FALSE
    )
  ))
  # Get the stock's stock split data within the specified date range
  tempSplits = getSplits(stock, from = fromDate, to = toDate, auto.assign = FALSE)
  tempSplits = as.data.frame(tempSplits)
  colnames(tempSplits) = "split"
  
  return (tempData)
}

# Adjust Open, Close, and SMA calculations to reflect the actual price the stock traded for at the time (unadjusted for splits)
for (i in 1:nrow(tempSplits)) {
  tempData <<- as.data.frame(tempData) %>%
    mutate(Open =
             case_when(
               rownames(as.data.frame(tempData)) <
                 rownames(tempSplits)[i] ~
                 Open/tempSplits$split[i],
               TRUE ~ Open),
           Close = case_when(
             rownames(as.data.frame(tempData)) <
               rownames(tempSplits)[i] ~
               Close/tempSplits$split[i],
             TRUE ~ Close),
           SMA = case_when(
             rownames(as.data.frame(tempData)) <
               rownames(tempSplits)[i] ~
               SMA/tempSplits$split[i],
             TRUE ~ SMA)
    )
}

# Keep only data with valid calculations
tempData = na.omit(tempData)

# Add columns for the closing stock price 22-28 days out
for (j in 22:28) {
  text = paste0("futureprice", j)
  tempData[text] = lead(tempData$Close, j)
}

# Add the next day's open price and the option strike price rounded up to the nearest 5
tempData$buyprice = lead(tempData$Open, 1)
tempData$strikeprice = round_any(tempData$buyprice, 5, ceiling)

# Add a row to get option strike price adjusted for stock split
adjStrikeprice = cbind(rownames(tempData), tempData$strikeprice)

# Add strike price calculations to reflect the actual strike price the stock option would have had at the time (unadjusted for splits)
for (m in 1:nrow(tempSplits)) {
  adjStrikeprice = as.data.frame(adjStrikeprice) %>%
    mutate(V2 = case_when(
      as.Date(lead(as.data.frame(adjStrikeprice)$V1, 28)) > as.Date(rownames(tempSplits)[m]) ~
        as.numeric(V2) * tempSplits$split[m],
      TRUE ~ as.numeric(V2)
    ))
}
tempData = cbind(tempData, adjStrikeprice$V2)

# Calculate returns based on if close price on days 22-28 is above strike price
for (l in 22:28) {
  x = logical(length(tempData$Open))
  futprice = paste0("futureprice", l)
  text = paste0("return", l)
  for (n in 1:nrow(tempSplits)) {
    t1 = as.Date(lead(rownames(tempData), l)) > as.Date(rownames(tempSplits)[n])
    t2 = as.Date(rownames(tempData)) < as.Date(rownames(tempSplits)[n])
    tmpx = Reduce("&", list(t1, t2))
    x <<- Reduce("|", list(x, tmpx))
  }
  # Calculate returns with split adjusted close price and split unadjusted close price
  y = Delt(x1 = tempData$`adjStrikeprice$V2`, x2 = as.numeric(unlist(tempData[futprice])))
  z = Delt(x1 = tempData$strikeprice, x2 = as.numeric(unlist(tempData[futprice])))
  # If a stock split occurred within index date and specified futureprice, use adjusted close price in Delt calculation
  tempData[text] <- ifelse(x, y, z)
}

# Keep only the dates with specified signals (RSI <= 35, SMI <= -20, Close >= 100-day SMA)
tempData = filter(tempData, rsi <= 35, SMI <= -20, Close >= SMA)