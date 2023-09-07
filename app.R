# Covid Viral Gene Concentration in Wastewater
#
# Dan (d2718) <dx2718@gmail.com>

library(dplyr)
library(ggplot2)
library(shiny)
library(tibble)

US_DATE_FMT <- "%m/%d/%Y"
LOCAL_COUNTIES <- c("Durham", "Orange", "Wake")

viral <- as_tibble(
  read.csv("viral.csv")
) |>
  select(-1) |>
  `colnames<-`(c(
    "plant", "co", "date", "pop_served", "gene_per_capita", "gene_per_l"
  )) |>
  mutate(
    date = as.Date(.data[["date"]], format = US_DATE_FMT),
    total_gene = pop_served * gene_per_capita
  )

# This data isn't used yet, but will be when I figure out exactly how
# to use it.
# hospital <- as_tibble(
#   read.csv("hospital.csv", header = FALSE)
#  ) |>
#   `colnames<-`(c(
#     "date", "covid_hosp", "adult_covid_icu", "ventilated_covid",
#     "covid_24h", "flu_24h"
#   )) |>
#   mutate(date = as.Date(.data[["date"]], format = US_DATE_FMT))

local_viral <- viral |>
  filter(co %in% LOCAL_COUNTIES) |>
  mutate(mgene_per_cap = gene_per_capita / 1000000)

co_names <- unique(local_viral$co)

ui <- fluidPage(
  verticalLayout(
    titlePanel("Triangle-Area Wastewater Viral Gene Counts"),
    plotOutput("the_plot"),
    fluidRow(
      column(2,
        checkboxGroupInput(
          "county", "County",
          choices = co_names,
          selected = "Durham"
        )
      ),
      column(2,
        checkboxGroupInput(
          "avg_counties", "Average Over",
          choices = co_names
        )
      ),
      column(2,
        radioButtons(
          "scale", "Scale",
          choices = list("Linear" = 1, "Logarithmic" = 2),
          selected = 1
        )
      ),
      column(6,
        sliderInput(
          "smoothing", "Smoothing",
          value = 0.15, min = 0.05, max = 0.25
        ),
        checkboxInput(
          "show_points", "Show Raw Data",
          value = FALSE
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  output$the_plot <- renderPlot({
    avg_cos <- input$avg_counties
    data <- filter(local_viral, co %in% input$county)
    
    p <- ggplot(
      data,
      aes(x = date, y = mgene_per_cap, color = plant)
    ) +
      geom_smooth(method = "loess", span = input$smoothing) +
      ylim(0, 150) +
      xlab("Date") +
      ylab("Millions of Viral Gene Copies per Person") +
      scale_color_discrete(name = "Treatment\nPlant")
    
    if(length(avg_cos) > 0) {
      avg_dat <- filter(local_viral, co %in% avg_cos) |>
        group_by(date) |>
        summarize(avg = sum(total_gene) / (sum(pop_served) * 1000000))
      
      avg_label <- paste0(
        "Average (",
        paste(avg_cos, collapse = ", "),
        ")"
      )
      
      p <- p + geom_smooth(
        aes(x = date, y = avg, color = avg_label),
        avg_dat,
        span = input$smoothing
      )
    }
    
    if(input$show_points) {
      p <- p + geom_point(alpha = 0.3)
    }
    
    if(input$scale == 2) {
      p <- p + scale_y_log10()
    }
    
    p
  })
}

shinyApp(ui = ui, server = server)
