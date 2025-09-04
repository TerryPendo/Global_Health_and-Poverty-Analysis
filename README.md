# 🌍 CEMA Data Science Project

## 📖 Introduction
This project was developed as part of the **CEMA Data Science assignment**.  
The goal was to analyze the relationship between **HIV prevalence** and **multidimensional poverty** across different regions and years.  

The analysis was implemented in **R** with an **interactive Shiny dashboard** for visualization.

---

## 📂 Project Structure
- 📁 `shapefiles/` → Geospatial files for mapping  
- 📄 `app.R`, `server.R`, `ui.R` → Shiny application code  
- 📊 `dataset_datascience.csv` → Cleaned dataset used in the app  
- 📊 `HIV data 2000-2023.csv` → Raw HIV prevalence data  
- 📊 `multidimensional_poverty.xlsx` → Multidimensional poverty index data  
- 📝 `Teresia_Mwagona.Rmd` → R Markdown report of the analysis  
- ⚙️ `manifest.json` → Metadata for project setup  

---

## 🔍 Methods
1. **Data Wrangling**: Cleaned and merged HIV and poverty datasets.  
2. **Exploratory Data Analysis (EDA)**: Summary statistics, correlations, and trends.  
3. **Visualization**:  
   - 📈 Line plots for HIV trends (2000–2023).  
   - 🗺️ Maps showing spatial distribution of poverty.  
   - 💻 Interactive Shiny dashboard for dynamic filtering.  
4. **Statistical Modeling**:  
   - Examined the association between HIV prevalence and poverty indicators.  

---

## 🛠️ Tools & Technologies
- 🟦 R, RStudio  
- ⚡ Shiny  
- 📊 ggplot2, dplyr  
- 🌐 Geospatial analysis with shapefiles

  ---

## 📊 Results
- 📉 HIV prevalence showed a general **declining trend** from 2000 to 2023.  
- 🤝 Higher poverty indices were associated with higher HIV prevalence in some regions.  
- 🖥️ The Shiny app allows users to explore these patterns interactively.  

---

## 📸 Dashboard Preview
![Dashboard Screenshot](dashboard1.screenshot.png)

---

## 🌐 Live Dashboard
👉 [Click here to try the interactive Shiny Dashboard](https://0196803d-274e-45e0-ad5e-9aabf3aafcde.share.connect.posit.cloud/)

