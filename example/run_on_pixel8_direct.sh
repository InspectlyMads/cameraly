#!/bin/bash

# Script to run the Cameraly example app directly on the Pixel 8 physical device
# with the specific device ID

# Pixel 8 device ID
DEVICE_ID="43260DLJH000DX"

echo "Running Cameraly example app on Pixel 8 (ID: $DEVICE_ID)..."

# Run the app on the Pixel 8
cd "$(dirname "$0")" && flutter run -d $DEVICE_ID

echo "App launched on Pixel 8." 