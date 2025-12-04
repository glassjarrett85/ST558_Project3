# Required tidy* libraries and seed

library(tidyverse)
library(tidymodels)
library(knitr)
set.seed(2358)

# The data set to be used across each file

df <- readr::read_csv("diabetes_binary_health_indicators_BRFSS2015.csv", show_col_types = FALSE) |>
  drop_na() |>
  select(Diabetes_binary, HighChol, BMI, HeartDiseaseorAttack, PhysActivity,
         GenHlth, PhysHlth, DiffWalk, Sex, Age) |>
  mutate(Diabetes_binary = factor(Diabetes_binary, levels=c(0,1),
                                  labels=c("Not diabetic", "Diabetic or Pre-diabetic")),
         HighChol = factor(HighChol, levels=c(0,1), labels=c("No", "Yes")),
         HeartDiseaseorAttack = factor(HeartDiseaseorAttack, levels=c(0,1),labels=c("No", "Yes")),
         PhysActivity = factor(PhysActivity, levels=c(0,1), labels=c("None", "Some")),
         GenHlth = factor(GenHlth, levels=c(1,2,3,4,5), labels=c("Excellent", "Very Good", "Good", "Fair", "Poor")),
         DiffWalk = factor(DiffWalk, levels=c(0,1), labels=c("No", "Yes")),
         Sex = factor(Sex, levels=c(0,1), labels=c("Female", "Male")),
         Age = factor(Age, levels=1:14,
                      labels=c("18-24", "25-29", "30-34", "35-39","40-44", "45-49", "50-54", "55-59", 
                               "60-64", "65-69", "70-74", "75-79","80+", "Not given")))

# The factor-specific variables for the /pred function in API
factors <- df |> select(where(is.factor)) |> map(levels)

# Quick function to get the mode of a vector. I already know there are no NA values in the data set, no need to account for this.
get_mode <- function(x) {
  ux <- unique(x)
  freqs <- tabulate(match(x, ux))
  ux[which(freqs == max(freqs))]
}

# Find the mode level of categorical variables and the mean values of numeric variables.
defaults <- df |>
  select(-Diabetes_binary) |>
  summarize(across(where(~is.numeric(.)), .fns=mean, .names="{.col}"),
            across(where(~is.factor(.) | is.character(.)), .fns=get_mode, .names="{.col}"))
defaults <- as.list(defaults)