shinyApp(ui = ui, server = server)
options(timeout = 600)  # Set timeout to 600 seconds (10 minutes)
install.packages("sf")
install.packages("promises")



