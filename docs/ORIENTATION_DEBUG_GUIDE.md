# Orientation Debug Guide

## Overview

The camera app now includes comprehensive orientation tracking and debugging features to ensure photos display correctly across all Android devices.

## Debug Overlay

### Enabling Debug Mode
- **Long press** anywhere on the camera screen to toggle the debug overlay
- The overlay shows real-time orientation data

### Information Displayed
- **Device**: Manufacturer and model information
- **OS Version**: Android/iOS version
- **Calculated Orientation**: Current device orientation in degrees (0°, 90°, 180°, 270°)
- **Accuracy Score**: Confidence level based on available sensors (0-100%)
- **Accelerometer**: X, Y, Z axis values (if available)
- **Gyroscope**: X, Y, Z rotation values (if available)

### Landscape Mode
In landscape orientation, the debug overlay automatically resizes to a fixed width (350px) to avoid filling the entire screen.

## Gallery Metadata

### Viewing Orientation Data
1. Open any photo in the gallery
2. Tap the **info button** (ℹ️) in the top controls
3. The info dialog now shows:
   - Basic file information
   - **Orientation Details** (if available):
     - Device manufacturer and model
     - Device angle at capture time
     - Camera rotation needed
     - Sensor orientation
     - Accuracy score
     - Additional metadata (lens direction, API level, etc.)

## How Orientation Data is Stored

When a photo is captured:
1. Orientation data is collected from device sensors
2. Device-specific corrections are applied
3. Data is saved as a JSON sidecar file: `photo.jpg.orientation.json`

## Testing Orientation

### Quick Test Steps
1. Enable debug overlay (long press)
2. Rotate device to different orientations
3. Take photos in each orientation:
   - Portrait (0°)
   - Landscape left (90°)
   - Portrait upside down (180°)
   - Landscape right (270°)
4. Switch between front and back cameras
5. Check gallery info to verify orientation data was captured

### What to Look For
- **Accuracy Score**: Should be above 50% for reliable orientation
- **Device Angle**: Should match physical device orientation
- **Camera Rotation**: Calculated correction needed for proper display

## Troubleshooting

### No Orientation Data
- Ensure device has accelerometer (most modern devices do)
- Check if sensors are working in device settings
- Try restarting the app

### Low Accuracy Score
- 0-50%: Only accelerometer data available
- 50-80%: Accelerometer working well
- 80-100%: Both accelerometer and gyroscope available

### Device-Specific Issues
The app includes corrections for:
- Samsung devices (90° default rotation)
- Xiaomi devices (270° default rotation)
- Huawei devices (180° with flip for front camera)
- And many others...

If you encounter issues with a specific device, note:
1. Device manufacturer and model (shown in debug overlay)
2. Orientation values when issue occurs
3. Whether it affects front camera, back camera, or both

## Production Notes

Currently, orientation data is captured and stored but not applied to the actual image. To complete the implementation:
1. Native platform code is needed to rotate images
2. EXIF orientation tags need to be written
3. Video orientation support needs to be added

The framework is complete and ready for these final implementation steps.