# API File for ST558 Project 3

# Data set established in the helper.R file
source("helper.R")

# Import these variables saved from Modeling.qmd 
split <- readRDS("split.rds")
rfBest <- readRDS("rfBest.rds")

# Generate the model using optimum conditions established in the `Modeling` page.
# In this case the tuned hyperparameters are mtry=2, min_n=2.
engine <- rand_forest(mtry=2, min_n=2, trees=100) |>
  set_engine("ranger", importance="impurity") |>
  set_mode("classification")

# Establish workflow
wkfl <- workflow() |>
  add_model(engine) |>
  add_formula(Diabetes_binary ~ .)

# There is no need to tune; so generate the model directly on `df`
final_fit <- wkfl |> fit(data=df)

library(plumber)

#* @apiTitle Binary Diabetes Model API
#* @apiDescription An API that provides predictions and other details from a predictive model based on the CDC's Diabetes questionnaire from 2015.


#* Provides the author's name and the URL to the processed Github pages.
#* @get /info
function() {
  return(list(
    status="success",
    name="Jarrett Glass",
    github_url="https://glassjarrett85.github.io/ST558_Project3/"
  ))
}


#* A prediction endpoint. This endpoint should take in any predictors used in your ‘best’ model. Multiple variables can be entered if separated by ampersand (&).
#* @param ... The variable(s) to be predicted against, and its predicted values. Multiple variables can be entered if separated by ampersands (&).
#* @serializer json
#* @get /pred
function(..., res, req) {
  args <- list(...)

  # Check if the arguments came through as a single string needing to be parsed.
  if (length(names(args)) == 1 && names(args) == "...") {
    pairs <- unlist(strsplit(args$..., "&"))
    parsed <- lapply(pairs, function(x) {
      parts <- unlist(strsplit(x, "="))
      if (length(parts) == 2) setNames(list(parts[2]), parts[1])
      else NULL
    })
    args <- unlist(parsed, recursive=FALSE)
  }
  else { }
  
  # Just make sure to remove the names "res", "req", or "session" from the list of args.
  args <- args[!(names(args) %in% c("res", "req", "session"))]

  # Confirm there is at least one variable provided.
  if (length(args) == 0) {
    res$status <- 400 # Bad request
    return(list(error = "No predictor variables provided. At least one is required."))
  }
  
  # Check if any of the proffered variables are not within allowable list of variables (`defaults`)
  invalids <- names(args)[!(names(args) %in% names(defaults))]
  if (length(invalids)) { 
    res$status <- 400 # Bad request
    return(list(
      error = "Invalid predictors provided:",
      bad_predictors = invalids
    ))
  }
  
  # Check the type of predictor, and convert to factor if needed.
  args <- args |>
    imap(~ {
      if (.y %in% names(factors)) factor(.x, levels = factors[[.y]])
      else as.numeric(.x)
    })
  
  # Create prediction data frame, replacing default values with user-specific ones.
  preds <- as.data.frame(c(args, defaults[!(names(defaults) %in% names(args))]))
  
  # Confirm that no inappropriate factor levels are provided.
  if (preds |> select(where(is.factor)) |> is.na() |> any()) {
    res$status <- 400 # Bad request
    return(list(
      error = "Inappropriate predictor level provided. For factor variables, only the following responses are allowable:",
      responses=factors
    ))
  }
  
  # Make the prediction from RF model
  prediction <- predict(final_fit, preds)
  
  # Finally return the result
  return(list(
    status="success",
    input_data=args,
    prediction=prediction$.pred_class[1]
  ))
}


#* Plot the confusion matrix for the model fit. That is, comparing the predictions from the model to the actual values from the data set (again you fit the model on the entire data set for this part).
#* @serializer png
#* @get /confusion
function() {
  # Using `last_fit` to get the necessary test data and predictions
  rfPreds <- rfBest |> 
    last_fit(split) |>
    collect_predictions()
  
  # Generate the confusion matrix using the actual Diabetes_binary variable versus the predicted values from the test set
  confmat <- rfPreds |>
    conf_mat(truth = Diabetes_binary, estimate = .pred_class)
  
  # Create the plot using a heatmap
  print(
    autoplot(confmat, type="heatmap") +
      labs(title="Confusion Matrix of Random Forest Model")
  )
}

# Three easy function calls to the /pred:

# /pred?PhysActivity=Some&DiffWalk=Yes&HeartDiseaseorAttack=Yes&HighChol=Yes&BMI=32
# /pred?HighChol=No&DiffWalk=No&GenHlth=Poor
# /pred?Age=75-79&GenHlth=Good&HighChol=Yes