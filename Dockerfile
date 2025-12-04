# Describes how to build the image.

# Base image we have or can download.
FROM rstudio/plumber

# Some Linux commands to install all the things we need to do this 'web trafficking business'.
RUN apt-get update -qq && apt-get install -y libssl-dev libcurl4-gnutls-dev libpng-dev libpng-dev pandoc

# Install needed libraries in R.
RUN R -e "install.packages(c('tidyverse', 'tidymodels', 'ranger','rpart.plot'))"

# Copy my API, Helper, and variable files to the image.
COPY api.R \
  helper.R \
  rfBest.rds \
  split.rds \
  diabetes_binary_health_indicators_BRFSS2015.csv \
  .

# Open the communication port.
EXPOSE 8000

# On start of the container, run this code.
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=8000)"]

# To run this now:
# docker build -t st558-api .
# docker run -p 8000:8000 st558-api
# docker save -o st558_api_image.tar st558-api