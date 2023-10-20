#!/bin/bash

# Author: [Dulanjana Lakmal]
# Date: [2022/10/23]

# Replace these variables with your own values
S3_BUCKET_NAME="yourbacket_name"
EMAIL_RECIPIENT="youremail@gmail.com"

# Function to send an email
send_email() {
    local subject=$1
    local body=$2
    echo "$body" | mail -s "$subject" "$EMAIL_RECIPIENT"
}

# Temporarily store the MongoDB dump
DUMP_DIR="/tmp/mongo_dump"

# MongoDB connection details
MONGO_URI="mongodb://<username>:<password>@<hostname>:<port>/<database_name>?authSource=admin"

# Get the current date in YYYY-MM-DD format
CURRENT_DATE=$(date +"%Y-%m-%d")

# Perform MongoDB dump
echo "Performing MongoDB dump..."
mongodump --uri="$MONGO_URI" --out "$DUMP_DIR"

# Check if the dump was successful
if [ $? -eq 0 ]; then
    echo "MongoDB dump completed successfully."

    # Create a tarball of the dump directory
    TAR_FILE="/tmp/mongo_dump.tar.gz"
    tar -zcvf "$TAR_FILE" -C "$DUMP_DIR" .

    # Upload the tarball to the S3 bucket in the new directory
    S3_DIRECTORY="mongodb_dumps/eu/$CURRENT_DATE"
    echo "Uploading the MongoDB dump to S3 bucket: $S3_BUCKET_NAME/$S3_DIRECTORY..."
    aws s3 cp "$TAR_FILE" "s3://$S3_BUCKET_NAME/$S3_DIRECTORY/"

    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "MongoDB dump uploaded successfully to S3 bucket: $S3_BUCKET_NAME."
        # Send success email notification
        send_email "MongoDB Dump Upload Success" "The MongoDB dump was successfully uploaded to the S3 bucket: $S3_BUCKET_NAME."
    else
        echo "Failed to upload the MongoDB dump to S3 bucket: $S3_BUCKET_NAME."
        # Send failure email notification
        send_email "MongoDB Dump Upload Failed" "The MongoDB dump upload to S3 bucket: $S3_BUCKET_NAME failed. Please check the logs."
    fi

    # Remove the temporary files
    rm -rf "$DUMP_DIR" "$TAR_FILE"
else
    echo "Failed to perform MongoDB dump."
    # Send failure email notification
    send_email "MongoDB Dump Failed" "The MongoDB dump operation failed. Please check the logs."
fi
