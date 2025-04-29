library(tidyverse)
library(ggplot2)
library(sf)
library(plotly)
library(leaflet)
library(scales)
library(shiny)
library(shinydashboard)
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

# Load and preprocess data (assuming datasets are available in the working directory)
hiv_data <- read_csv("HIV data 2000-2023.csv",show_col_types = FALSE) %>%
  filter(!str_detect(Value, "No data|<")) %>%
  mutate(
    HIV_Population_raw = str_extract(Value, "^[^\\[]+"),
    HIV_Population_clean = str_replace_all(HIV_Population_raw, "\\s", ""),
    HIV_Population = as.numeric(HIV_Population_clean)
  ) %>%
  filter(!is.na(HIV_Population)) %>%
  select(-HIV_Population_raw, -HIV_Population_clean, -Value) %>%
  rename(Value = HIV_Population)

# Calculate top 75% HIV burden countries globally
total_hiv_by_country <- hiv_data %>%
  filter(!is.na(Value)) %>%
  group_by(Location) %>%
  summarise(total_hiv = sum(Value, na.rm = TRUE)) %>%
  arrange(desc(total_hiv)) %>%
  mutate(
    cum_sum = cumsum(total_hiv),
    cum_percent = cum_sum / sum(total_hiv)
  )

top75_countries <- total_hiv_by_country %>%
  filter(cum_percent <= 0.75) %>%
  pull(Location)

hiv_trend_data <- hiv_data %>%
  filter(Location %in% top75_countries, !is.na(Value))

# Calculate top 75% HIV burden countries by WHO region
hiv_clean <- hiv_data %>%
  filter(!is.na(Value))

top75_by_region <- hiv_clean %>%
  group_by(ParentLocationCode, Location) %>%
  summarise(total_hiv = sum(Value, na.rm = TRUE), .groups = "drop") %>%
  group_by(ParentLocationCode) %>%
  arrange(desc(total_hiv), .by_group = TRUE) %>%
  mutate(
    cum_sum = cumsum(total_hiv),
    region_total = sum(total_hiv),
    cum_percent = cum_sum / region_total
  ) %>%
  filter(cum_percent <= 0.75) %>%
  select(ParentLocationCode, Location)

hiv_top75 <- hiv_clean %>%
  inner_join(top75_by_region, by = c("ParentLocationCode", "Location"))

# Load mortality data
mortality_dataset <- read_csv("dataset_datascience.csv")
u5_mortality_rate <- mortality_dataset %>% filter(Indicator == "Under-five mortality rate")
neonatal_rate <- mortality_dataset %>% filter(Indicator == "Neonatal mortality rate")

# Define EAC countries
eac_countries <- c("Burundi", "Democratic Republic of the Congo", "Kenya",
                   "Rwanda", "Somalia", "South Sudan", "Uganda", "United Republic of Tanzania")

# Filter and process mortality data
under_five_eac <- u5_mortality_rate %>%
  filter(`Geographic area` %in% eac_countries) %>%
  mutate(
    Year = ifelse(
      str_detect(`Series Year`, "-"),
      str_sub(`Series Year`, -4, -1),
      `Series Year`
    ),
    Year = as.numeric(Year)
  )

neonatal_eac <- neonatal_rate %>%
  filter(`Geographic area` %in% eac_countries) %>%
  mutate(
    Year = ifelse(
      str_detect(`Series Year`, "-"),
      str_sub(`Series Year`, -4, -1),
      `Series Year`
    ),
    Year = as.numeric(Year)
  )

# Latest year mortality data
mortality_latest <- under_five_eac %>%
  filter(`Geographic area` %in% eac_countries) %>%
  group_by(`Geographic area`) %>%
  slice_max(order_by = Year, n = 1) %>%
  ungroup() %>%
  filter(Sex == "Total", `Wealth Quintile` == "Total") %>%
  group_by(`Geographic area`, Year) %>%
  summarise(Estimate = median(`Observation Value`, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(`Geographic area` = ifelse(`Geographic area` == "United Republic of Tanzania", "Tanzania", `Geographic area`))

neonatal_latest <- neonatal_eac %>%
  filter(`Geographic area` %in% eac_countries) %>%
  group_by(`Geographic area`) %>%
  slice_max(order_by = Year, n = 1) %>%
  ungroup() %>%
  filter(Sex == "Total", `Wealth Quintile` == "Total") %>%
  group_by(`Geographic area`, Year) %>%
  summarise(Estimate = median(`Observation Value`, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(`Geographic area` = ifelse(`Geographic area` == "United Republic of Tanzania", "Tanzania", `Geographic area`))

unzip("gadm41_BDI_shp.zip", exdir = "shapefiles/")
unzip("gadm41_COD_shp.zip", exdir = "shapefiles/")
unzip("gadm41_KEN_shp.zip", exdir = "shapefiles/")
unzip("gadm41_RWA_shp.zip", exdir = "shapefiles/")
unzip("gadm41_SOM_shp.zip", exdir = "shapefiles/")
unzip("gadm41_SSD_shp.zip", exdir = "shapefiles/")
unzip("gadm41_TZA_shp.zip", exdir = "shapefiles/")
unzip("gadm41_UGA_shp.zip", exdir = "shapefiles/")


# Load shapefiles (assuming they are in the working directory under shapefiles/)
kenya <- st_read("shapefiles/gadm41_KEN_0.shp")
uganda <- st_read("shapefiles/gadm41_UGA_0.shp")
tanzania <- st_read("shapefiles/gadm41_TZA_0.shp")
rwanda <- st_read("shapefiles/gadm41_RWA_0.shp")
burundi <- st_read("shapefiles/gadm41_BDI_0.shp")
south_sudan <- st_read("shapefiles/gadm41_SSD_0.shp")
drc <- st_read("shapefiles/gadm41_COD_0.shp")
somalia <- st_read("shapefiles/gadm41_SOM_0.shp")

eac_countries1 <- bind_rows(kenya, uganda, tanzania, rwanda, burundi, south_sudan, drc, somalia)

# Merge shapefiles with mortality data
eac_map_mortality <- left_join(eac_countries1, mortality_latest, by = c("COUNTRY" = "Geographic area"))
eac_map_neonatal <- left_join(eac_countries1, neonatal_latest, by = c("COUNTRY" = "Geographic area"))

# Simplify shapefiles
eac_map_mortality_simple <- rmapshaper::ms_simplify(eac_map_mortality, keep = 0.05, keep_shapes = TRUE)
eac_map_neonatal_simple <- rmapshaper::ms_simplify(eac_map_neonatal, keep = 0.05, keep_shapes = TRUE)

# Calculate average mortality trends
mortality_avg <- under_five_eac %>%
  group_by(Year) %>%
  summarize(Average_Estimate = mean(`Observation Value`, na.rm = TRUE))

neonatal_avg <- neonatal_eac %>%
  group_by(Year) %>%
  summarize(Average_Estimate = mean(`Observation Value`, na.rm = TRUE))

# Server logic
server <- function(input, output) {
  output$hiv_country_trends <- renderPlotly({
    p <- ggplot(hiv_trend_data, aes(x = Period, y = Value, color = Location)) +
      geom_line() +
      geom_point() +
      facet_wrap(~Location, scales = "free_y", nrow = 3) +
      labs(
        title = "HIV Cases Trend by Country (75% Global HIV Burden)",
        x = "Period",
        y = "Number of People Living with HIV"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 18)
      )
    ggplotly(p)
  })
  
  output$hiv_region_trends <- renderPlotly({
    p <- ggplot(hiv_top75, aes(x = Period, y = Value, color = Location)) +
      geom_line(linewidth = 1) +
      facet_wrap(~ParentLocationCode, scales = "free_y") +
      scale_y_continuous(labels = scales::comma) +
      labs(
        title = "HIV Trends (2000–2023) in Top 75% Burden Countries Within Each WHO Region",
        x = "Year",
        y = "Estimated People Living with HIV",
        color = "Country"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        legend.position = "right",
        plot.title = element_text(hjust = 0.5, size = 18),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12),
        legend.key.size = unit(0.7, "cm"),
        legend.spacing.y = unit(0.5, "cm")
      ) +
      guides(color = guide_legend(ncol = 1))
    ggplotly(p)
  })
  
  output$selectedMap <- renderLeaflet({
    if (input$map_choice == "underFive") {
      pal <- colorNumeric(viridis::viridis(50), domain = eac_map_mortality_simple$Estimate)
      leaflet(data = eac_map_mortality_simple) %>%
        addTiles() %>%
        addPolygons(
          fillColor = ~pal(Estimate),
          color = "black",
          weight = 1,
          fillOpacity = 0.7,
          popup = ~paste("Country: ", COUNTRY, "<br>", "Mortality Rate: ", round(Estimate, 1))
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal,
          values = ~Estimate,
          title = "Under-5 Mortality Rate",
          opacity = 1
        )
    } else {
      pal2 <- colorNumeric(viridis::viridis(50), domain = eac_map_neonatal_simple$Estimate)
      leaflet(data = eac_map_neonatal_simple) %>%
        addTiles() %>%
        addPolygons(
          fillColor = ~pal2(Estimate),
          color = "black",
          weight = 1,
          fillOpacity = 0.7,
          popup = ~paste("Country: ", COUNTRY, "<br>", "Neonatal Mortality Rate: ", round(Estimate, 1))
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal2,
          values = ~Estimate,
          title = "Neonatal Mortality Rate",
          opacity = 1
        )
    }
  })
  
  output$under5_mortality_trends <- renderPlotly({
    p <- ggplot() +
      geom_line(data = mortality_avg, aes(x = as.factor(Year), y = Average_Estimate, group = 1), color = "black", size = 0.8) +
      geom_point(data = under_five_eac, aes(x = as.factor(Year), y = `Observation Value`, color = `Geographic area`), size = 1.0) +
      theme_minimal() +
      labs(
        title = "Under-5 Mortality Rate Trends (EAC Countries)",
        x = "Year",
        y = "Mortality Rate (per 1000 live births)",
        color = "Country"
      ) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 12),
        axis.title = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12)
      )
    ggplotly(p)
  })
  
  output$neonatal_mortality_trends <- renderPlotly({
    p <- ggplot() +
      geom_line(data = neonatal_avg, aes(x = Year, y = Average_Estimate), color = "black", size = 0.5) +
      geom_point(data = neonatal_eac, aes(x = Year, y = `Observation Value`, color = `Geographic area`), size = 0.5) +
      theme_minimal() +
      labs(
        title = "Neonatal Mortality Rate Trends (EAC Countries)",
        x = "Year",
        y = "Mortality Rate (per 1000 live births)",
        color = "Country"
      ) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 18),
        axis.text = element_text(size = 14),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12)
      )
    ggplotly(p)
  })
}