#!/bin/bash

echo "Predicting using Python API for Cloud ML Engine Model"

PROJECT_ID=$(gcloud config list project --format "value(core.project)")
BUCKET_NAME=${PROJECT_ID}-recommendation-system-bucket

# Copying files to data folder
DATA_FOLDER=$(pwd)/data
mkdir $DATA_FOLDER
gsutil -m cp -r gs://$BUCKET_NAME/data $DATA_FOLDER 

#Calling the python API
python inference.py --predict-file $DATA_FOLDER/test.csv