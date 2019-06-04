library(rvest)
library(dplyr)
library(stringr)
library(shiny)

# Data Web Scraping
teampage <- read_html("http://www.baseball-reference.com/teams/")
fran_name <- teampage %>% html_nodes(".left") %>% html_text()
fran_name <- fran_name[2:31]
s <- html_session("http://www.baseball-reference.com/teams/")
baseball <- data.frame()

for(i in 1:length(fran_name)) {  #length(fran_name)
  hist <- s %>% follow_link(fran_name[i]) %>% read_html()
  sub_tb <- as.data.frame(hist %>% html_nodes("#franchise_years") %>% html_table())
  sub_tb['Team'] <- fran_name[i]
  baseball <- rbind(baseball, sub_tb)
}

all.equal(charToRaw(baseball$Tm[1]), charToRaw("Arizona Diamondbacks"))

char_cols <- which(lapply(baseball, typeof) == "character")

for(i in char_cols){
  baseball[[i]] <- str_conv(baseball[[i]], "UTF-8")
  baseball[[i]] <- str_replace_all(baseball[[i]],"\\s"," ")
}

all.equal(charToRaw(baseball$Tm[1]), charToRaw("Arizona Diamondbacks"))

dim(baseball)

# Use data from 1969-2018
baseball <- baseball %>% filter(Year %in% 1969:2018)
baseball <- subset(baseball, select = -Tm)
baseball$GB[which(baseball$GB == "--")] <- 0
baseball$GB <- as.integer(baseball$GB)
# Categorize attendance to indicate popularity
baseball$Attendance <- as.numeric(gsub("," ,"", baseball$Attendance))
baseball$Popularity <- cut(baseball$Attendance, breaks=c(-Inf, 1000000, 2000000, 3000000, Inf),
                           labels=c("Very unpopular", "Unpopular", "Popular", "Very popular"))
baseball$Lg <- as.factor(baseball$Lg)
baseball$Popularity <- as.factor(baseball$Popularity)

# Linear model with all predictors
m1 <- lm(W.L. ~ Lg + GB + R + RA + Popularity + BatAge + PAge + X.Bat + X.P, data = baseball)
summary(m1)
# Removing insignificant predictors
m2 <- lm(W.L. ~ Lg + GB + R + RA + Popularity + PAge + X.Bat, data = baseball)
summary(m2)

# Run our regression
fit <- lm(W.L. ~ Lg + GB + R + RA + Popularity + PAge + X.Bat, data = baseball)

preds <- function(fit, Lg, GB, R, RA, Popularity, PAge, X.Bat){
  # get the predicted win-loss percentage from new data
  W.L. <- predict(object = fit, 
                  newdata = data.frame(Lg = factor(Lg, levels = c("AL Central", "AL East", "AL West", 
                                                                  "NL Central", "NL East", "NL West")),
                                       GB = GB, R = R, RA = RA,
                                       Popularity = factor(Popularity, levels = c("Very unpopular",
                                                                                  "Unpopular", "Popular",
                                                                                  "Very popular")), 
                                       PAge = PAge, X.Bat = X.Bat))
  
  # return as character string that can be easily rendered
  return(as.character(round(W.L., 3)))
}



app <- shinyApp(ui = fluidPage(titlePanel('Predicting Winning Rate for MLB Teams'),
                               
                               sidebarLayout(
                                 sidebarPanel(h3("Introduction"),
                                              p("This shiny app is used to predict the winning rate of a 
                                              certain team in a baseball game from some features of this 
                                              team and the players. The multiple linear regression model 
                                              it employed was built based on data collected on some MLB 
                                              teams.")),
                                 mainPanel(img(src = "MLB.png", height = 200, width = 300))),
                               
                               # create inputs for each variable in the model
                               
                               radioButtons('Lg', label = 'League',
                                            choices = levels(baseball$Lg),
                                            inline=TRUE),
                                               
                               sliderInput('GB', label = 'Games back of league leader',
                                           min = floor(min(baseball$GB)), 
                                           max = ceiling(max(baseball$GB)),
                                           value = floor(mean(baseball$GB))),
                                               
                               sliderInput('R', label = 'Runs scored', 
                                           min = floor(min(baseball$R)), 
                                           max = ceiling(max(baseball$R)),
                                           value = floor(mean(baseball$R))),
                                               
                               sliderInput('RA', label = 'Runs allowed', 
                                           min = floor(min(baseball$RA)), 
                                           max = ceiling(max(baseball$RA)),
                                           value = floor(mean(baseball$RA))),
                                               
                               radioButtons('Popularity', label = 'Popularity based on tickets sold in home games',
                                            choices = levels(baseball$Popularity),
                                            inline=TRUE),
                                               
                               sliderInput('PAge', label = "Pitchers' average age", 
                                           min = floor(min(baseball$PAge)), 
                                           max = ceiling(max(baseball$PAge)),
                                           value = floor(mean(baseball$PAge))),
                                               
                               sliderInput('X.Bat', label = 'Number of batters used in games', 
                                           min = floor(min(baseball$X.Bat)), 
                                           max = ceiling(max(baseball$X.Bat)),
                                           value = floor(mean(baseball$X.Bat))),
                               
                               sidebarLayout(
                                 position = 'right',
                                 sidebarPanel(h4("Predicted Winning Rate: ", textOutput('prediction'))),
                                 mainPanel = "  ")),
                
                
                server = function(input, output){
                  # pass our inputs to our prediction function defined earlier
                  # and pass that result to the output
                  output$prediction <- renderText({
                    preds(fit = fit, 
                          Lg = input$Lg,
                          GB = input$GB,
                          R = input$R,
                          RA = input$RA,
                          Popularity = input$Popularity, 
                          PAge = input$PAge, 
                          X.Bat = input$X.Bat)
                     
                  })
                })

