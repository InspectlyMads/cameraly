# iOS Permission Setup Guide

## Overview
This guide explains how to properly configure iOS permissions for the camera app.

## Required Steps

### 1. Info.plist Configuration
The following entries have been added to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos with audio</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save captured photos and videos</string>
```

### 2. Podfile Configuration
The following has been added to `ios/Podfile`:

1. Platform version set to iOS 12.0:
```ruby
platform :ios, '12.0'
```

2. Permission handler flags in post_install:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Permission handler configuration
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

### 3. Running Pod Install
After making these changes, run:
```bash
cd ios
pod install
```

### 4. Clean Build
If permissions still don't work:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter build ios
```

## Testing Permissions

1. Use the "Debug Permissions (iOS)" button on the home screen to test permission requests
2. The debug screen will show the status of each permission
3. You can request permissions individually or all at once
4. If permissions are denied, use "Open App Settings" to navigate to iOS settings

## Common Issues

### Issue: Permissions not showing up
- Make sure you've run `pod install` after updating the Podfile
- Clean and rebuild the project
- Delete the app from the simulator/device and reinstall

### Issue: Camera/Microphone permission not requested
- Verify Info.plist has the correct usage descriptions
- Check that the permission_handler flags are set in Podfile
- Ensure platform version is iOS 12.0 or higher

### Issue: App crashes when requesting permissions
- This usually means the usage descriptions are missing from Info.plist
- Double-check all three descriptions are present

## Debugging Tips

1. Check Xcode console for permission-related errors
2. Use the PermissionTestScreen to debug permission states
3. Print permission status before and after requests
4. Check iOS Settings > Privacy to see if permissions are listed