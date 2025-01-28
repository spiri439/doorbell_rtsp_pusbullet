#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 \"subject\" \"message\""
    exit 1
fi

# Input arguments
SUBJECT="$1"
MESSAGE="$2"

# FTP credentials
FTP_HOST=""
FTP_USER=""
FTP_PASS=""

# RTSP stream URL
RTSP_URL="rtsp://admin:pass@192.168.0.50:554/ch4/main/av_stream"

# List of Pushbullet API keys (recipients)
RECIPIENTS=(
    "o.SecondApiKeyExample123456B"
    "o.SecondApiKeyExample123456"
    "o.ThirdApiKeyExample654321"
)

# Generate timestamped file name in hourminuteseconddaymonthyear format
TIMESTAMP=$(date +"%H%M%S%d%m%Y")
IMAGE_FILE="/tmp/${TIMESTAMP}.jpg"
FTP_FILE="${TIMESTAMP}.jpg"

# Public URL for the uploaded file
FTP_PUBLIC_URL="https://tld.tld/${FTP_FILE}"

# Capture image from RTSP stream
ffmpeg -y -i "$RTSP_URL" -vframes 1 "$IMAGE_FILE" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to capture image from RTSP stream."
    exit 1
fi

# Upload the image to the FTP server
curl -T "$IMAGE_FILE" --ftp-create-dirs --user "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/$FTP_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to upload image to FTP server."
    exit 1
fi

# Send Pushbullet notification to each recipient
for API_KEY in "${RECIPIENTS[@]}"; do
    curl -s -u "$API_KEY:" \
        -X POST https://api.pushbullet.com/v2/pushes \
        -H "Content-Type: application/json" \
        -d '{
            "type": "file",
            "title": "'"$SUBJECT"'",
            "body": "'"$MESSAGE"'",
            "file_url": "'"$FTP_PUBLIC_URL"'",
            "file_type": "image/jpeg",
            "file_name": "'"${FTP_FILE}"'"
        }' > /dev/null

    if [ $? -ne 0 ]; then
        echo "Failed to send notification to API key: $API_KEY"
    else
        echo "Notification sent successfully to API key: $API_KEY"
    fi
done

# Cleanup
rm -f "$IMAGE_FILE"
