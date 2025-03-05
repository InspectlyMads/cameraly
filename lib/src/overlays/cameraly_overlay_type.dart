/// Defines the types of overlays that can be displayed on top of the camera preview.
///
/// This enum is used to specify whether to show no overlay, the default overlay
/// provided by the package, or a custom overlay provided by the developer.
enum CameralyOverlayType {
  /// No overlay is displayed.
  ///
  /// Use this when you want a clean camera preview without any controls.
  none,

  /// The default overlay provided by the Cameraly package is displayed.
  ///
  /// This overlay includes standard camera controls like capture button,
  /// flash toggle, camera switch, etc.
  defaultOverlay,

  /// A custom overlay provided by the user is displayed.
  ///
  /// Use this when you want to implement your own camera UI.
  custom,
}
