#!/bin/bash

# Script to run the Cameraly example app on Pixel 8 physical device

# Get the device ID for the Pixel 8
DEVICE_ID=$(flutter devices | grep "Pixel 8" | awk '{print $2}')

if [ -z "$DEVICE_ID" ]; then
  echo "Pixel 8 device not found. Make sure it's connected and detected by Flutter."
  exit 1
fi

echo "Found Pixel 8 device with ID: $DEVICE_ID"
echo "Running Cameraly example app on Pixel 8..."

# Run the app on the Pixel 8
flutter run -d $DEVICE_ID

echo "App launched on Pixel 8." 