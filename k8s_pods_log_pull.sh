#!/bin/bash

# Author: [Dulanjana Lakmal]
# Date: [2023/04/13]

# Specify the Kubernetes context and S3 bucket name
k8s_context="kubernetes-admin@<your_cluster>"
S3_BUCKET_NAME="<s3_bucket_name>"

# Set Kubernetes context
kubectl config use-context "$k8s_context"

# Get the logger pod name
logger_pod=$(kubectl get pods -n <namespace> | grep <pod_name> | awk '{print $1}')

# Check if the logger pod was found
if [ -n "$logger_pod" ]; then
    # Create a temporary directory
    TEMP_DIR="/tmp/kubectl_logs"
    mkdir -p "$TEMP_DIR"

    # Copy all log files from the pod to the temporary directory
    kubectl cp <pod_name>"$logger_pod":/app/logs/ "$TEMP_DIR"

    # Check if the copy was successful
    if [ $? -eq 0 ]; then
        echo "Log files copied successfully from pod $logger_pod."

        # Upload each log file to the S3 bucket using the AWS CLI
        for log_file in "$TEMP_DIR"/*.log.gz; do
            if [ -f "$log_file" ]; then
                log_filename=$(basename "$log_file")
                echo "Uploading $log_filename to S3 bucket: $S3_BUCKET_NAME..."
                aws s3 cp "$log_file" "s3://$S3_BUCKET_NAME/$logger_pod/$log_filename"
                
                # Check if the upload was successful
                if [ $? -eq 0 ]; then
                    echo "$log_filename uploaded successfully to S3 bucket: $S3_BUCKET_NAME."
                else
                    echo "Failed to upload $log_filename to S3 bucket: $S3_BUCKET_NAME."
                fi
            fi
        done

        # Clean up the temporary directory
        rm -rf "$TEMP_DIR"
    else
        echo "Failed to copy log files from pod $logger_pod."
    fi
else
    echo "Logger pod not found in namespace."
fi
