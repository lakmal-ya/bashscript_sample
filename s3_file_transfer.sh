#!/bin/bash

# Author: [Dulanjana Lakmal]
# Date: [2023/04/20]

# Replace these variables with your own values
S3_BUCKET_NAME="<s3_bucket_name>"
EMAIL_RECIPIENT="your_email@gmail.com"

# Function to send an email
send_email() {
    local subject=$1
    local body=$2
    echo "$body" | mail -s "$subject" "$EMAIL_RECIPIENT"
}

# URL to download the file from
URL="<third_part_url_need_file_need_to_download_fomr>"

# Temporarily store the downloaded file
TEMP_FILE="./<Temporarily_store_the_downloaded_file>"

# Download the file using wget
echo "Downloading the file from $URL..."
wget -q "$URL" -O "$TEMP_FILE"

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "File downloaded successfully."

    # Upload the file to the S3 bucket using the AWS CLI
    echo "Uploading the file to S3 bucket: $S3_BUCKET_NAME..."
    aws s3 cp "$TEMP_FILE" "s3://$S3_BUCKET_NAME/"
    
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "File uploaded successfully to S3 bucket: $S3_BUCKET_NAME."
        # Send success email notification
        send_email "File Upload Success" "The file was successfully uploaded to the S3 bucket: $S3_BUCKET_NAME."
    else
        echo "Failed to upload the file to S3 bucket: $S3_BUCKET_NAME."
        # Send failure email notification
        send_email "File Upload Failed" "The file upload to S3 bucket: $S3_BUCKET_NAME failed. Please check the logs."
    fi

    # Remove the temporary file
    rm -f "$TEMP_FILE"
else
    echo "Failed to download the file from $URL."
    # Send failure email notification
    send_email "File Download Failed" "The file download from $URL failed. Please check the logs."
fi
