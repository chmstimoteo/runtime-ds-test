#!/bin/bash

echo "Running Tensorboard to inspect traning summary"

if [ -n "$OUTPUT_PATH" ];
then
    echo 'Running tensorboard at http://127.0.0.1'
    tensorboard --logdir=$OUTPUT_PATH --host=127.0.0.1
else
    echo 'Cannot run tensorboard - $OUTPUT_PATH not set'
fi