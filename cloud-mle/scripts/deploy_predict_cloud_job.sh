#!/bin/bash

echo "Deploying and Predicting using a Cloud ML Engine Model"

PROJECT_ID=$(gcloud config list project --format "value(core.project)")
TIER="STANDARD_1" # BASIC | BASIC_GPU | STANDARD_1 | PREMIUM_1
BUCKET_NAME=${PROJECT_ID}-recommendation-system-bucket
REGION=us-central1

TRAIN_DATA=gs://$BUCKET_NAME/data/train.data.csv
EVAL_DATA=gs://$BUCKET_NAME/data/test.data.csv
TEST_CSV=gs://$BUCKET_NAME/data/test.csv

CURRENT_DATE=`date +%Y%m%d_%H%M%S`
PREDICTION_JOB_NAME=rec_sys_prediction_$CURRENT_DATE

# Select the job output to use
OUTPUT_PATH=gs://$BUCKET_NAME/$TRAINING_JOB_NAME

# set the environment variable MODEL_BINARIES to its value
# An example: MODEL_BINARIES=gs://$BUCKET_NAME/RecSys_hptune_20180801_175727/4/export/RecSys/1533161602/
MODEL_BINARIES=""

# check if model binaries is set
if [ -z "$MODEL_BINARIES" ];
then
    echo 'Set variable $MODEL_BINARIES'
    # Look up the full path of your exported trained model binaries:
    echo "Printing the output path. Select a path for the binary file..."    
    if [ $JOB_TYPE = "distributed-hypertune" ];
    then
        gsutil ls -r $OUTPUT_PATH/
    else
        gsutil ls $OUTPUT_PATH/export/rec_sys/ | tail -1
    fi
else
    # deploy the model
    MODEL_NAME=RecSysModel_$CURRENT_DATE
    MODEL_VERSION=v1

    # Create a Cloud ML Engine model
    gcloud ml-engine models create $MODEL_NAME --regions=$REGION

    # Run the following command to create a version v1
    gcloud ml-engine versions create $MODEL_VERSION \
    --model $MODEL_NAME \
    --origin $MODEL_BINARIES \
    --runtime-version 1.8

    # submit a batched job
    gcloud ml-engine jobs submit prediction $PREDICTION_JOB_NAME \
    --model $MODEL_NAME \
    --version $MODEL_VERSION \
    --data-format TEXT \
    --region $REGION \
    --input-paths $TEST_CSV \
    --output-path $OUTPUT_PATH/predictions

    # stream job logs
    echo "Job logs..."
    gcloud ml-engine jobs stream-logs $PREDICTION_JOB_NAME

    # read output summary
    echo "Job output summary:"
    gsutil cat $OUTPUT_PATH/predictions/prediction.results-00000-of-00001
fi