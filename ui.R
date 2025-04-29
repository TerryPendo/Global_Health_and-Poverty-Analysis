library(shiny)
library(shinydashboard)
library(shinyjs)
library(viridis)
library(plotly)
library(tidyverse)    
library(ggplot2)      
library(sf)           
library(lme4)
library(plotly)
library(dplyr)
library(stringr)
library(viridis)
library(scales)
library(leaflet)

ui <- dashboardPage(
  skin = "purple",  # Modern color theme
  dashboardHeader(
    title = span(tagList(icon("chart-bar"), "CEMA Data Science Visualizations")),
    titleWidth = 300
  ),
  dashboardSidebar(
    disable = TRUE  # Sidebar disabled as per the provided code
  ),
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        /* Make fonts nicer */
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        /* Center dashboard title */
        .main-header .logo { font-weight: bold; font-size: 22px; }
      "))
    ),
    fluidRow(
      column(width = 12, plotlyOutput("hiv_country_trends", height = "600px"))
    ),
    br(),
    fluidRow(
      column(width = 12, plotlyOutput("hiv_region_trends", height = "800px"))
    ),
    br(),
    fluidRow(
      column(
        width = 6,
        h3("Select Map"),
        selectInput(
          "map_choice",
          label = "Choose a Map",
          choices = list(
            "Under-5 Mortality Rate" = "underFive",
            "Neonatal Mortality Rate" = "neonatal"
          ),
          selected = "underFive"
        )
      )
    ),
    fluidRow(
      column(width = 12, leafletOutput("selectedMap", height = "600px"))
    ),
    br(),
    fluidRow(
      column(width = 12, plotlyOutput("under5_mortality_trends", height = "600px"))
    ),
    br(),
    fluidRow(
      column(width = 12, plotlyOutput("neonatal_mortality_trends", height = "600px"))
    )
  )
)