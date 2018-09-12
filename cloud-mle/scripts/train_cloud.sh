#!/bin/bash

echo "Submitting a Cloud ML Engine job..."

PROJECT_ID=$(gcloud config list project --format "value(core.project)")
TIER="BASIC" # BASIC | BASIC_GPU | STANDARD_1 | PREMIUM_1
BUCKET=$PROJECT_ID"-recommendation-system-bucket" # change to your bucket name

CURRENT_DATE=`date +%Y%m%d_%H%M%S`
JOB_NAME=RecSys_single_$CURRENT_DATE # for hyper-parameter tuning jobs

MODEL_NAME=trainer.task
PACKAGE_PATH=trainer/ # this can be a gcs location to a zipped and uploaded package
TRAIN_FILES=gs://$BUCKET/data/train.data.csv
EVAL_FILES=gs://$BUCKET/data/test.data.csv
MODEL_DIR=gs://$BUCKET/models/$JOB_NAME
MODEL_DIR_DIST=gs://$BUCKET/models-dist/$JOB_NAME
TEST_JSON=gs://$BUCKET/data/test.json

#submit training job
gcloud ml-engine jobs submit training $JOB_NAME --job-dir $MODEL_DIR --runtime-version 1.8 --scale-tier=$TIER --module-name $MODEL_NAME --package-path $PACKAGE_PATH -- --train-files $TRAIN_FILES --eval-files $EVAL_FILES --train-steps 1000 --eval-steps 100 --verbosity DEBUG --embedding-size 128 --dense-size 128 --l2-regularization 0.1 --l2-bias-regularization 0.05 --user-item-multiply False --learning-rate 0.0002
gcloud ml-engine jobs stream-logs $JOB_NAME

# notes:
# use --packages instead of --package-path if gcs location
# add --reuse-job-dir to resume training
