#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# The purpose of this app is to provides easy access to the graphical and numerical summaries 
# of variables (demographics, lab measurements, vitals) in the ICU cohort.
# 
# Author: Puyuan Liu
# Date: 2024-02-29
library(bigrquery)
library(dbplyr)
library(DBI)
library(gt)
library(gtsummary)
library(shiny)
library(tidyverse)
library(stringr)


# connect to the BigQuery database `biostat-203b-2024-winter.mimic4_v2_2`
con_bq <- dbConnect(
  bigrquery::bigquery(),
  project = "biostat-203b-2024-winter",
  dataset = "mimic4_v2_2",
  billing = "biostat-203b-2024-winter"
)

icu_cohort <- read_rds("mimic_icu_cohort.rds")
mimic_icu_cohort <- icu_cohort %>%
  mutate(los_grouped = cut(los, breaks = c(0, 5, 10, 20, 30, Inf), 
                           labels = c("0-5", "5-10", 
                                      "10-20", "20-30", "30+"))) |>
  mutate(age_group = cut(age, breaks = c(18, 30, 40, 50, 60, 70, 80, 90, Inf), 
                         labels = c("18-30", "30-40", "40-50", "50-60", 
                                    "60-70", "70-80", "80-90", "90+")))

# Define a function to set the line width based on the care unit
line_width <- function(x) {
  4*grepl("(ICU|CCU)", x) + 2.5
}

extract_before_comma <- function(x) {
  parts <- strsplit(x, ",")[[1]]
  return(parts[1])
}



# Define UI for application that draws a histogram
ui <- navbarPage(
  # Application title
  titlePanel("Summaries and Visualizations of ICU Cohort"),
  h4("Author: Puyuan Liu"),
  tabPanel("Patients Characteristics",
           sidebarPanel(
             selectInput(
               inputId = "demographic_var", 
               label = "Select Demographic Variable", 
               choices = c("Race" = "race",
                           "Insurance" = "insurance",
                           "Marital Status" = "marital_status",
                           "Gender" = "gender", 
                           "Age at intime" = "age_group")
             ),
             
             selectInput(
               inputId = "lab_var", 
               label = "Select Lab Measurements Variable", 
               choices = c("Bicarbonate",
                           "Chloride",
                           "Creatinine",
                           "Glucose",
                           "Potassium",
                           "Sodium",
                           "Hematocrit",
                           "White Blood Cells")
             ),
             
             selectInput(
               inputId = "vital_var", 
               label = "Select Vital Measurements Variable", 
               choices = c("Heart Rate",
                           "Non Invasive Blood Pressure systolic",
                           "Non Invasive Blood Pressure diastolic",
                           "Respiratory Rate",
                           "Temperature Fahrenheit")
             )
           ),
           
           mainPanel(
             tabsetPanel(
               tabPanel(
                 title = "Demographics Summary", 
                 gt_output("demographic_table"), 
                 plotOutput("demographic_plot")
               ),
               
               tabPanel(
                 title = "Lab Measurements", 
                 plotOutput("lab_plot")
               ),
               
               tabPanel(
                 title = "Vital Measurements",
                 plotOutput("vital_plot")
               )
             )
           )
  ),
  
  
  tabPanel("Patient's ADT and ICU stay information",
           numericInput(inputId = "patient_id",
                        label = "Input Patient ID",
                        value = 10001217),
           mainPanel(
             plotOutput("adt_history"),
             plotOutput("icu_stays")
           )
)
)

# Define server
server <- function(input, output){
  
  # Reactive expression for selected demographic variable
  selected_var1 <- reactive({
    input$demographic_var
  })
  
  selected_var2 <- reactive({
    input$lab_var
  })
  
  selected_var3 <- reactive({
    input$vital_var
  })
  
  patient_id <- reactive({
    input$patient_id
  })
  
  # Reactive expression for numeric summary

  numeric_summary <- reactive({
      summary_stats <- mimic_icu_cohort %>%
        group_by_at(vars(selected_var1())) %>%
        summarize(
          mean_los = mean(los, na.rm = TRUE),
          median_los = median(los, na.rm = TRUE),
          min_los = min(los, na.rm = TRUE),
          max_los = max(los, na.rm = TRUE),
          sd_los = sd(los, na.rm = TRUE),
          count = n()
        )
      return(summary_stats)
  })
  
  
  
  # Render the numeric summary as a pretty table using gt
  output$demographic_table <- render_gt({
    numeric_summary() %>%
      gt() %>%
      tab_header(
        title = "Demographic Summary",
        subtitle = paste("Summary of length of ICU stay by",
                         input$demographic_var)
      )
  })
  
  
  output$demographic_plot <- renderPlot({
    ggplot(mimic_icu_cohort,  
           aes_string(x = "los_grouped", fill = selected_var1())) +
      geom_bar(position = "fill", color = "white") +
      labs(title = paste("Percentage of ICU Length of Stay by", 
                         input$demographic_var),
           x = "Length of ICU Stay",
           y = "Percentage") +
      scale_y_continuous(labels = scales::percent_format(scale = 1)) +
      theme_light()
  })
  
  
  output$lab_plot <- renderPlot({
    ggplot(mimic_icu_cohort,
           aes_string(x = selected_var2(), y = "los")) +
    geom_smooth(method = 'gam', formula = y ~ s(x, bs = "cs")) +
    labs(title = paste("Length of ICU stays vs 
                       Last available lab measurements of", 
                       input$lab_var, "before ICU stay"),
         x = paste("Last available lab measurements of", 
                   input$lab_var,  "before ICU stay"),
         y = "Length of ICU stays (days)") 
  })
  
  
  output$vital_plot <- renderPlot({
    ggplot(mimic_icu_cohort,
           aes(x = !!as.symbol(selected_var3()), y = los)) +
      geom_smooth(method = 'gam', formula = y ~ s(x, bs = "cs")) +
      labs(title = paste("Length of ICU stays vs first measurements of", 
                         input$vital_var, "within ICU stay"),
           x = paste("First measurements of", 
                     input$vital_var,  "within ICU stay"),
           y = "Length of ICU stays (days)") 
  })
  
  
  # Extract datasets and filter useful information
  patients <- reactive({tbl(con_bq, "patients") |>
    filter(subject_id == !!patient_id()) |>
    select(subject_id, gender, anchor_age, anchor_year)
  })
  
  admissions <- reactive({tbl(con_bq, "admissions") |>
    filter(subject_id == !!patient_id()) |>
    select(subject_id, race)|>
    distinct()
  })
  
  adt <- reactive({
    tbl(con_bq, "transfers") |>
      filter(subject_id == !!patient_id() 
             & !is.na(intime) & !is.na(outtime) & !is.na(careunit)) |>
      select(intime, outtime, careunit)
  })
  
  lab <- reactive({tbl(con_bq, "labevents") |>
    filter(subject_id == !!patient_id()) |>
    select(charttime)|>
    distinct()
  })
  
  procedures_icd <- reactive({tbl(con_bq, "procedures_icd") |>
    filter(subject_id == !!patient_id()) |>
    select(subject_id, seq_num, icd_code, chartdate)
  })
  
  diagnoses_icd <- reactive({tbl(con_bq, "diagnoses_icd") |>
    filter(subject_id == !!patient_id()) |>
    select(subject_id, seq_num, icd_code)
  })
  
  d_icd_procedures <- reactive({tbl(con_bq, "d_icd_procedures") |>
    select(icd_code, long_title)
  })
  
  d_icd_diagnoses <- reactive({tbl(con_bq, "d_icd_diagnoses") |>
    select(icd_code, long_title)
  })
  
  diag_icd <- reactive({
    left_join(diagnoses_icd(), d_icd_diagnoses(), by = "icd_code") |>
      select(long_title, icd_code)|>
      distinct()
  })
  
  procedure <- reactive({
    left_join(procedures_icd(), d_icd_procedures(), by = "icd_code") %>%
      select(chartdate, long_title)
  })
  
  patient_profile <- reactive({
    left_join(patients(), admissions(), by = "subject_id")
  })
  
  output$adt_history <- renderPlot({
    blank_plot <- ggplot() +
      labs(title = paste("Patient",
                         patient_profile() %>% pull(subject_id), ",",
                         patient_profile() %>% pull(gender), ",",
                         patient_profile() %>% pull(anchor_age) + 
                           year(adt() %>% pull(intime)) - 
                           patient_profile() %>% pull(anchor_year),
                         "years old,",
                         patient_profile() %>% pull(race)),
           subtitle = {
             long_titles <- diag_icd() %>% pull(long_title)
             if (!is.null(long_titles) && length(long_titles) >= 3) {
               str_c(str_to_lower(long_titles[1:3]), collapse = "\n")
             } else {
               str_c(str_to_lower(long_titles), collapse = "\n")
             }
           }, 
           x = "Calendar time",
           y = "") +
      scale_y_discrete(limits = c("Procedure", "Lab", "ADT")) +
      theme_light()
    
    # Plot the first layer with ADT history.
    adt_plot <- blank_plot + 
      geom_segment(data = adt(), aes(x = intime,
                                   xend = outtime,
                                   y = "ADT", 
                                   yend = "ADT",
                                   color = careunit),
                   linewidth = line_width(adt() %>% pull(careunit))) +
      guides(color = guide_legend(title = "Care Unit", ncol = 3, order = 1)) +
      theme(legend.position = "bottom") 
    
    # Plot the second layer with lab events.
    lab_plot <- adt_plot +
      geom_point(data = lab(), aes(x = charttime, y = "Lab"),
                 shape = 3, size = 2.5, color = "black") 
    
  
    full_plot <- lab_plot +
      geom_point(data = procedure(), aes(x = as.POSIXct(chartdate, 
                                                      format="%Y-%m-%d"),
                                       y = "Procedure", 
                                       shape = str_sub(
                                         procedure() %>% pull(long_title), 
                                         1, 
                                         35
                                         )
                                       ),
                 size = 4,
                 color = "black") +
      guides(shape = guide_legend(title = "Procedure", 
                                  ncol = 3,
                                  order = 2, 
                                  horiz = T), 
             label = c("Dilation of Coronary Artery", "Long")) +
      scale_shape_manual(values = c(1:n_distinct(procedure() %>%
                                                   pull(long_title)))) +
      theme(legend.text = element_text(size = 8),
            legend.position = "bottom", legend.box = "vertical") 
    print(full_plot)
  })
  
  
  d_items <- reactive({tbl(con_bq, "d_items") |>
    filter(abbreviation %in% c("HR", "NBPd", "NBPs", "RR", "Temperature F")) |>
    select(itemid, label, abbreviation)
  })
  
  chartevents <- reactive({tbl(con_bq, "chartevents") |>
    filter(subject_id == !!patient_id()) |>
    filter(itemid %in% c(220045, 220180, 220179, 223761, 220210)) |>
    left_join(d_items(), by = "itemid") |>
    select(subject_id, stay_id, charttime, valuenum, abbreviation)
  })
    
  
  output$icu_stays <- renderPlot({
    ggplot(chartevents(), aes(x = charttime,
                              y = valuenum, 
                              color = abbreviation)) +
      geom_point(size = 1.2) +
      geom_line() +
      facet_grid(rows = vars(abbreviation), 
                 cols = vars(stay_id),
                 scales = "free") +
      labs(title = paste("Patient", 
                         patient_profile() %>% pull(subject_id), 
                         "ICU Stays - vitals"), 
           x = "", 
           y = "") +
      scale_x_datetime(labels = scales::date_format("%b %d %H:%M"),
                       guide = guide_axis(n.dodge = 2)) +
      theme_light() + 
      theme(axis.text = element_text(size = 7.5)) +
      guides(color = "none")
  })
}

  
# Run the Shiny app
shinyApp(ui, server)





