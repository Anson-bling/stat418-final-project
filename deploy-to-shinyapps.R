
# Deploy to shinyapps.io
# First you will need an account

#install.packages('rsconnect')

# Name is account name, get both your authentication token and secret in your account
rsconnect::setAccountInfo(name = 'mysticcc',
                          token = '<hide>',
                          secret = '<SECRET>')

setwd("~/Desktop/stat418-final-project")
library(rsconnect)
rsconnect::deployApp(appDir = 'docker/app/', appName = "Predicting_Winning_Rate_for_MLB_Teams")

# This is now running at
# https://mysticcc.shinyapps.io/Predicting_Winning_Rate_for_MLB_Teams/