# This is the API file.

# You’ll create a file that defines an API (via the plumber package). At the top of the file, read in your data and fit your ‘best’ model to the entire data set.
# 
# Then you should create three API endpoints:
#   
# + A pred endpoint. This endpoint should take in any predictors used in your ‘best’ model. You should have default values for each that is the mean of that variable’s values (if numeric) or the most prevalent class (if categorical). Below this API put three example function calls to the API in comments so that I can easily copy and paste to check that it works!
#   
# + An info endpoint. This endpoint shouldn’t have any inputs. The output should be a message with:
#   – Your name
#   – A URL for your rendered github pages site
# 
# + A confusion endpoint. This endpoint should produce a plot of the confusion matrix for your model fit. That is, comparing the predictions from the model to the actual values from the data set (again you fit the model on the entire data set for this part).


# Begin with copying over the script from the example we worked on. This will be baseline to begin working.

library(plumber)

#* @apiTitle Plumber Example API
#* @apiDescription Plumber example description.

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg = "") {
  list(msg = paste0("The message is: '", msg, "'"))
}

#* Plot a histogram
#* @serializer png
#* @get /plot
function() {
  rand <- rnorm(100)
  hist(rand)
}

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
function(a, b) {
  as.numeric(a) + as.numeric(b)
}

# Programmatically alter your API
#* @plumber
function(pr) {
  pr %>%
    # Overwrite the default serializer to return unboxed JSON
    pr_set_serializer(serializer_unboxed_json())
}

library(leaflet)
#* Plotting widget
#* @serializer htmlwidget
#* @param lat latitude
#* @param lng longtitude
#* @get /map
function(lng=174.768, lat=-36.852) {
  m <- leaflet::leaflet() |>
    addTiles() |> # Add default OpenStreetMap map tiles
    addMarkers(as.numeric(lng), as.numeric(lat))
  m # print the map
}