# Cameraly - Project Structure Guide

This document provides a quick reference to the organization of files and directories in the Cameraly project.

## Root Directory

```
cameraly/
├── lib/                  # Main package code
├── example/              # Example application
├── test/                 # Test files
├── doc/                  # Additional documentation
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration
├── pubspec.yaml          # Package dependencies
├── README.md             # Package documentation
├── CHANGELOG.md          # Version history
├── LICENSE               # License information
├── TASKS.md              # Development tasks and progress
└── CONTEXT.md            # Quick context guide
```

## Library Structure

```
lib/
├── cameraly.dart         # Main package entry point
└── src/                  # Implementation files
    ├── cameraly_controller.dart    # Camera control implementation
    ├── cameraly_preview.dart       # Camera preview widget
    ├── cameraly_value.dart         # State management
    ├── exceptions/                 # Custom exceptions
    │   └── cameraly_exception.dart
    ├── extensions/                 # Dart extensions
    │   └── camera_extensions.dart
    ├── overlays/                   # Overlay system
    │   ├── cameraly_overlay_theme.dart
    │   ├── cameraly_overlay_type.dart
    │   ├── default_cameraly_overlay.dart
    │   └── overlay_position.dart
    ├── types/                      # Data models and settings
    │   ├── camera_device.dart
    │   ├── capture_settings.dart
    │   ├── photo_settings.dart
    │   └── video_settings.dart
    ├── utils/                      # Utility functions
    │   ├── cameraly_utils.dart
    │   └── permission_handler.dart
    └── widgets/                    # Reusable widgets
        └── focus_indicator.dart
```

## Example App Structure

```
example/
├── lib/                  # Example app code
│   ├── main.dart         # Entry point with navigation
│   ├── cameraly_example.dart  # Basic usage example
│   └── overlay_example.dart   # Overlay system demonstration
├── android/              # Android configuration
├── ios/                  # iOS configuration
└── pubspec.yaml          # Example app dependencies
```

## Test Structure

```
test/
├── unit/                 # Unit tests
│   ├── cameraly_controller_test.dart
│   ├── cameraly_value_test.dart
│   └── utils/
│       └── permission_handler_test.dart
├── widget/               # Widget tests
│   ├── cameraly_preview_test.dart
│   └── overlays/
│       └── default_cameraly_overlay_test.dart
└── integration/          # Integration tests
    └── cameraly_integration_test.dart
```

## Key Files

### Core Implementation

- **lib/cameraly.dart**: Main package entry point that exports all public APIs
- **lib/src/cameraly_controller.dart**: Core class for camera operations
- **lib/src/cameraly_preview.dart**: UI widget for camera preview
- **lib/src/cameraly_value.dart**: State container for camera information

### Overlay System

- **lib/src/overlays/cameraly_overlay_type.dart**: Enum for overlay types
- **lib/src/overlays/default_cameraly_overlay.dart**: Default camera UI
- **lib/src/overlays/cameraly_overlay_theme.dart**: Theme for styling overlays

### Settings

- **lib/src/types/capture_settings.dart**: Base settings class
- **lib/src/types/photo_settings.dart**: Photo-specific settings
- **lib/src/types/video_settings.dart**: Video-specific settings

### Utilities

- **lib/src/utils/cameraly_utils.dart**: Helper functions
- **lib/src/utils/permission_handler.dart**: Permission management

## Example App

- **example/lib/main.dart**: Entry point with navigation
- **example/lib/cameraly_example.dart**: Basic usage example
- **example/lib/overlay_example.dart**: Overlay system demonstration

## Documentation

- **README.md**: Main package documentation
- **TASKS.md**: Development tasks and progress
- **CONTEXT.md**: Quick context guide
- **PROJECT_STRUCTURE.md**: This file

## File Naming Conventions

- **Snake Case**: Used for all file names (e.g., `cameraly_controller.dart`)
- **Camel Case**: Used for directories (e.g., `src/overlays/`)

## Class Naming Conventions

- **Pascal Case**: Used for all classes (e.g., `CameralyController`)
- **Prefix**: All public classes use the "Cameraly" prefix (e.g., `CameralyPreview`)

## Import Organization

Imports should be organized in the following order:

1. Dart SDK imports
2. Flutter framework imports
3. External package imports
4. Cameraly package imports (relative paths)

Example:
```dart
// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';

// External package imports
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

// Cameraly imports
import '../cameraly_controller.dart';
import '../types/capture_settings.dart';
``` 