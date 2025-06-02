## MVP Core Concept & Scope

The goal is to build a very basic Flutter camera app as a Proof of Concept (PoC) specifically to test and understand how the `camera` package handles orientation on various Android devices. We want to see how the preview looks, and more importantly, how the *captured* photos and videos are oriented when saved.

**MVP Scope:**

*   **Home Screen:** List of camera modes.
*   **Camera Screen:** Live preview, capture button, basic controls (flash, camera toggle).
*   **Capture Output:** Saved to app-private storage, verified in a simple gallery.
*   **Focus on Orientation:** The primary testing target.

---

## MVP Feature Breakdown

Here's the plan, broken down into core features:

### 1. **Core App Setup & Permissions**

*   **Objective:** Get the basic Flutter app running and ensure it can access the camera and microphone.
*   **Key Components:**
    *   `main.dart`: Initialize Flutter, request camera and microphone permissions.
    *   `pubspec.yaml`: Add `camera`, `path_provider`, `permission_handler` dependencies.
    *   `AndroidManifest.xml` (Android): Declare necessary permissions (`CAMERA`, `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`/`READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO`).
*   **Orientation Considerations:** None directly at this stage, but critical for the camera to even function.

### 2. **Home Screen**

*   **Objective:** Provide a simple navigation point to different camera modes.
*   **Key Components:**
    *   `HomeScreen.dart`:
        *   A `Scaffold` with an `AppBar`.
        *   A `ListView` of `ListTile`s or `ElevatedButton`s.
        *   Each item navigates to the `CameraScreen`.
        *   Pass a `CameraMode` enum (e.g., `photosOnly`, `videosOnly`, `photosAndVideos`) to the `CameraScreen`.
*   **Orientation Considerations:** Standard Flutter UI, no special orientation handling needed here.

### 3. **Camera Screen (Shared Functionality)**

*   **Objective:** Implement the core camera logic that applies to all modes.
*   **Key Components:**
    *   `CameraScreen.dart`:
        *   `CameraController` initialization and disposal (crucial for lifecycle).
        *   Display `CameraPreview` widget.
        *   **Dynamic UI based on `CameraMode` passed from `HomeScreen`.**
        *   **Camera Toggle:** Button to switch between front/rear cameras (if available).
        *   **Flash Control:** Button to cycle through flash modes (off, auto, on, torch).
        *   **App Lifecycle Handling:** Properly pause/resume camera when the app goes to background/foreground (`WidgetsBindingObserver`). This is critical for Android.
*   **Orientation Considerations (HIGH PRIORITY):**
    *   **`CameraPreview`:** How does it render on different devices when the phone is held in various orientations (portrait, landscape left, landscape right, upside down)? Does it automatically adjust or stretch?
    *   **Device Rotation Listener (Advanced, but good to keep in mind):** While `CameraPreview` usually handles its own orientation based on the camera sensor, it's worth noting that your UI overlays might need to respond to device rotation. For this MVP, we'll keep the UI minimal to avoid complex rotation issues.
    *   **`CameraController` initialization:** Some devices might prefer specific resolutions or aspect ratios.

### 4. **Camera Screen (Photo Mode Specific)**

*   **Objective:** Enable taking single photos.
*   **Key Components:**
    *   **`CameraScreen.dart` (conditional UI/logic):**
        *   **Capture Button:** A single button for `takePicture()`.
        *   **Save Location:** Save `XFile` to a temporary directory using `path_provider`.
        *   **Visual Feedback:** A simple snackbar on capture success/failure.
*   **Orientation Considerations (CRITICAL FOR PoC):**
    *   **Captured Image Orientation:** When `takePicture()` is called, the resulting `XFile` should contain an image with the correct EXIF orientation tag, so that when opened in a standard gallery, it appears correctly oriented, *regardless of how the phone was held*. This is the *main test point*.
    *   Testing: Capture in Portrait, Landscape Left, Landscape Right. View results.

### 5. **Camera Screen (Video Mode Specific)**

*   **Objective:** Enable recording videos.
*   **Key Components:**
    *   **`CameraScreen.dart` (conditional UI/logic):**
        *   **Record Button:** Toggles `startVideoRecording()` and `stopVideoRecording()`.
        *   **Recording Indicator:** Simple UI change (e.g., red circle, timer) when recording.
        *   **Save Location:** Save `XFile` to a temporary directory.
        *   **Visual Feedback:** Snackbar on start/stop/failure.
*   **Orientation Considerations (CRITICAL FOR PoC):**
    *   **Captured Video Orientation:** Similar to photos, the resulting video file needs to have the correct rotation metadata so it plays correctly in a gallery app, *regardless of recording orientation*.
    *   Testing: Record in Portrait, Landscape Left, Landscape Right. View results. Look for videos that are sideways or upside down.

### 6. **Camera Screen (Photos & Videos Mode)**

*   **Objective:** Combine photo and video capabilities, mimicking a standard OS camera app.
*   **Key Components:**
    *   **`CameraScreen.dart` (conditional UI/logic):**
        *   **Mode Selector:** A toggle or segment control (e.g., "Photo" | "Video") to switch between capture types.
        *   The capture button's action will depend on the currently selected mode.
*   **Orientation Considerations:** Inherits all considerations from Photo and Video modes.

### 7. **Gallery Screen (Verification)**

*   **Objective:** A simple way to view the captured media *within the app* and verify their orientation.
*   **Key Components:**
    *   `GalleryScreen.dart`:
        *   Display a grid of `XFile` paths.
        *   For photos, use `Image.file()`.
        *   For videos, use `video_player` to display a thumbnail or a playable video preview.
        *   Provide a way to delete files for cleanup.
*   **Orientation Considerations:** This screen is where you explicitly check if `Image.file` and `video_player` render the media correctly *without* you applying any manual rotations. If they render correctly here, it's a good sign the `camera` package handled the metadata. **The ultimate test is opening them in the *device's native gallery app*.**

---

## Testing Strategy (Crucial for PoC)

*   **Device Variety:** Test on as many different Android phones as possible, especially older ones, less common brands, or devices known for camera quirks.
*   **Orientation Testing:**
    *   For *each* camera mode (photo, video, combined):
        *   Hold the device in **Portrait Upright**. Capture.
        *   Hold the device in **Landscape Left** (home button/USB port to the right). Capture.
        *   Hold the device in **Landscape Right** (home button/USB port to the left). Capture.
        *   (Optional, but good for edge cases) Hold device **upside down Portrait**. Capture.
    *   Immediately after capture, review the media in:
        1.  Your app's `GalleryScreen`.
        2.  The device's *native photo gallery app*. This is the gold standard for orientation verification.
*   **Lifecycle Testing:** Start camera, send app to background, bring to foreground. Does it resume correctly?
*   **Permission Denial:** Test what happens if camera/mic permissions are denied initially.
