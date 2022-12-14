#' -----------------------------------------------------------------
#' `15.780 Final Project`
#' `Time Series Analysis`
#' -----------------------------------------------------------------

# load libraries
library(tseries)
library(forecast)
library(ggplot2)
library(ggfortify)
library(haven)

# read data
df_db = read_dta('delbangclean.dta')
df_dm = read_dta('delmumbaiclean.dta')
df_bm = read_dta('bangmumbaiclean.dta')

# separate econ and business
df_db_e = subset(df_db, class == 'Economy')
df_db_b = subset(df_db, class == 'Business')

df_dm_e = subset(df_dm, class == 'Economy')
df_dm_b = subset(df_dm, class == 'Business')

df_bm_e = subset(df_bm, class == 'Economy')
df_bm_b = subset(df_bm, class == 'Business')

# 6 total dataframes
# update df variable to set and run one dataset at a time
df = df_bm_b
head(df)

# visualize data:
# 1. scatterplot
plot(df$days_left, df$price)
# 2. line plot, average price by days_left
ggplot(df, aes(days_left, price)) + stat_summary(geom = "line", fun = mean) +
  ggtitle("Average Price vs. Number of Days Before Flight")

# prepare data
# 1. drop unnecessary columns
df = subset(df[, c('days_left', 'price')])
# 2. group by days_left and average prices
df = aggregate(df$price, by=list(df$days_left), FUN=mean)
# 3. rename columns
names(df)[names(df) == "Group.1"] <- "days"
names(df)[names(df) == "x"] <- "price"
# 4. cast data as time series
price = ts(df$price)

# split data
# train = subset(df, df$days > 10)
# test = subset(df, df$days <= 10)


##############
# ARIMA model#
##############

# build model
am = auto.arima(price)
arimaorder(am)

# evaluate model
MAPE = function(actual, pred) {
  percent_errors = abs(actual - pred) / abs(actual)
  return(mean(percent_errors))
}

#train_pred = as.vector(am$fitted)
#train_actual = train$price
#train_mape = MAPE(train_actual, train_pred)

am.pred = as.vector(am$fitted)
am.actual = df$price
am.mape = MAPE(am.actual, am.pred)

ggtsdiag(am)

# forecast
forecast.am = forecast(am, h = 51, level = c(95))
autoplot(forecast.am) + 
  labs(x = "Days Left", y = "Price", title = "ARIMA Forecast of Price by Days Left") +
  ylim(0,70000)

###################
# Holt-Winters ES #
###################

# build model
es = HoltWinters(price, beta=FALSE, gamma=FALSE)

# evaluate model 
plot.ts(price)
lines(es$fitted[,1], col="blue")
legend(x = "topright", legend=c("Actual", "Forecast"),
       col=c("Black", "blue"), lty=1)
title("Holt-Winters Forecast of Price by Days Left")

es.pred = as.vector(es$fitted)
es.actual = df$price
es.mape = MAPE(es.actual, es.pred)


#####################
# Scenario Analysis #
#####################

# Parameters:
# Delhi to Mumbai
# 0 stops
# 2 hours
# Forecast next 50 days

# prepare data
df = subset(df_dm_e, source_city == 'Delhi' &
                    destination_city == "Mumbai" &
                    stops == 0 &
                    duration > 1.83 | duration < 4.03)
df = subset(df[, c('days_left', 'price')])
df = aggregate(df$price, by=list(df$days_left), FUN=mean)
names(df)[names(df) == "Group.1"] <- "days"
names(df)[names(df) == "x"] <- "price"
price = ts(df$price)

# build model - arima
model1 = auto.arima(price)
arimaorder(model)

# evaluate model
model1.pred = as.vector(model$fitted)
model1.actual = df$price
model1.mape = MAPE(model.actual, model.pred)

# forecast model
forecast.model1 = forecast(model, h = 51, level = c(95))
autoplot(forecast.model1) + 
        labs(x = "Days Left", y = "Price", title = "ARIMA Forecast of Price by Days Left") +
        ylim(0,11000)
print(forecast.model1)

# build model - es
model2 = HoltWinters(price, beta=FALSE, gamma=FALSE)

# forecast 
plot.ts(price)
lines(model2$fitted[,1], col="blue")
legend(x = "topright", legend=c("Actual", "Forecast"),
       col=c("Black", "blue"), lty=1)
title("Holt-Winters Forecast of Price by Days Left")
predict(model2, n.ahead=51, prediction.interval=TRUE, level=0.95)

# evaluate model
model2.pred = as.vector(model2$fitted)
model2.actual = df$price
model2.mape = MAPE(model2.actual, model2.pred)
