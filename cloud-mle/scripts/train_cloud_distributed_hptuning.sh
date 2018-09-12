#!/bin/bash

echo "Submitting a Cloud ML Engine job with hyper-parameter tuning..."

PROJECT_ID=$(gcloud config list project --format "value(core.project)")
TIER="STANDARD_1" # BASIC | BASIC_GPU | STANDARD_1 | PREMIUM_1
BUCKET_NAME=${PROJECT_ID}-recommendation-system-bucket
REGION=us-central1
JOB_TYPE="distributed-hypertune"

TRAIN_DATA=gs://$BUCKET_NAME/data/train.data.csv
EVAL_DATA=gs://$BUCKET_NAME/data/test.data.csv
TEST_CSV=gs://$BUCKET_NAME/data/test.csv

CURRENT_DATE=`date +%Y%m%d_%H%M%S`
TRAINING_JOB_NAME=rec_sys_hptune_$CURRENT_DATE
OUTPUT_PATH=gs://$BUCKET_NAME/$TRAINING_JOB_NAME
HPTUNING_CONFIG=$(pwd)/hptuning_config.yaml

# distributed training job WITH hyper-parameter tuning
gcloud ml-engine jobs submit training $TRAINING_JOB_NAME \
    --stream-logs \
    --job-dir $OUTPUT_PATH \
    --runtime-version 1.8 \
    --config $HPTUNING_CONFIG \
    --module-name trainer.task \
    --package-path trainer/ \
    --region $REGION \
    --scale-tier $TIER \
    -- \
    --train-files $TRAIN_DATA \
    --eval-files $EVAL_DATA \
    --train-steps 50000 \
    --verbosity DEBUG  \
    --eval-steps 100

# stream logs
echo "Streaming the logs..."
gcloud ml-engine jobs stream-logs $TRAINING_JOB_NAME