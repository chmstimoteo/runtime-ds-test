# Recommendation System with TensorFlow Estimators

Google Cloud MLE for inference and prediction of movie ratings.

- - -

This repository contains the code for building a movie recommender engine wrapped with the TensorFlow High-level Estimator API and scripts for performing model inference and prediction on Google Cloud Machine Learning Engine using distributed training and hyper-parameter tuning.

Before running the bash scripts in this folder, run `chmod -R +x scripts` to recursively set permissions for the script subfolder. Also, use `source ..` to run the bash scripts, so that the environment variables are set in the shell instance.

## Download the data
The transofrmed dataset for training and evaluation are stored on the Google Cloud Bucket `gs://eds-sandbox-186722-recommendation-system-bucket`

## Distributed Training
Run the distributed training code on the cloud by executing the following bash script,
```
source ./scripts/train_cloud_distributed.sh
```

## Hyperparameter Tuning
The configurations for hyper-parameter tuning are stored in the file `hptuning_config.yaml`. To train on Cloud ML Engine with automatic hyper-parameter tuning, run the script,
```
source ./scripts/train_cloud_distributed_hptuning.sh
```

## Deploy Model and Run Batch Prediction
To deploy the trained model and run batch predictions on Cloud MLE, run the script:
```
source ./scripts/deploy_predict_cloud_job.sh
```

## Predict using Python API
To predict using the Python API for Cloud MLE, run the script below. However, a service account `service-account.json`, (which will be made available on request) is required to run this file.
```
source ./scripts/predict_ratings.sh
```

## Tensorboard
Run Tensorboard to inspect details about the graph by using the script,
```
source ./scripts/tensorboard.sh
```