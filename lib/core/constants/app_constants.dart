class AppConstants {
  AppConstants._();

  // Spacing
  static const double space4  = 4;
  static const double space8  = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // Radii
  static const double radiusBubble  = 12;
  static const double radiusButton  = 8;
  static const double radiusInput   = 24;
  static const double radiusSidebar = 24;
  static const double radiusSmall   = 4;
  static const double radiusCard    = 12;

  // Layout
  static const double sidebarWidth             = 240;
  static const double headerHeight             = 48;
  static const double inputAreaHeight          = 64;
  static const double chatMaxWidth             = 800;
  static const double settingsPanelWidth       = 320;
  static const double bubbleMaxWidthFraction   = 0.80;
  static const double botBubbleMaxWidthFraction = 0.85;

  // Breakpoints
  static const double breakpointDesktop = 900;
  static const double breakpointTablet  = 640;

  // Animation durations (ms)
  static const int messageAppearMs        = 200;
  static const int threadFadeMs           = 200;
  static const int typingLoopMs           = 600;
  static const int typingStaggerMs        = 150;
  static const int threadStaggerMs        = 30;
  static const int settingsSlideDurationMs = 250;

  // Thread title max length
  static const int threadTitleMaxLength = 40;

  // Input max lines
  static const int inputMaxLines = 6;

  // Code block expand/collapse threshold (lines)
  static const int codeBlockCollapseLines = 15;
}
