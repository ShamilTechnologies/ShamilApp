# Enhanced Stroke Loader Overlay System - Usage Guide

## Overview
The Enhanced Stroke Loader with integrated overlay system provides a full-screen transparent loading interface that can be used throughout the app. The system handles loading, success, and error states with automatic timing and haptic feedback.

## Features
- **Full-screen transparent overlay** with dark background
- **State-aware stroke loader** (loading, success, error) 
- **Auto-dismiss functionality** with configurable timing
- **Haptic feedback** for all state transitions
- **Direct text handling** without container styling
- **Easy integration** from any screen

## Integration

### Import
```dart
import 'package:shamil_mobile_app/core/widgets/enhanced_stroke_loader.dart';
```

## Usage Examples

### 1. Loading State
Shows loading overlay with custom message:
```dart
// Show loading
LoadingOverlay.showLoading(
  context,
  message: 'Signing in to your account...',
);

// Manual dismiss (for loading states)
LoadingOverlay.hide();
```

### 2. Success State
Shows success overlay with auto-dismiss:
```dart
LoadingOverlay.showSuccess(
  context,
  message: 'Welcome back!',
  onComplete: () {
    // Navigate or perform action after success
    Navigator.pushReplacement(context, NextScreen());
  },
);
// Auto-dismisses after 2 seconds
```

### 3. Error State
Shows error overlay with auto-dismiss:
```dart
LoadingOverlay.showError(
  context,
  message: 'Invalid credentials',
  onComplete: () {
    // Handle error state after overlay dismisses
    setState(() {
      hasError = true;
    });
  },
);
// Auto-dismisses after 3 seconds
```

### 4. Custom Timing
Override default auto-dismiss timing:
```dart
LoadingOverlay.showSuccess(
  context,
  message: 'Verification email sent',
  autoDismissAfter: const Duration(seconds: 4),
  onComplete: () {
    // Custom completion logic
  },
);
```

## Default Timings
- **Loading**: Manual dismiss only
- **Success**: 2 seconds auto-dismiss
- **Error**: 3 seconds auto-dismiss

## Auth Integration Example
```dart
void _handleAuthStateChanges(BuildContext context, AuthState state) {
  if (state is AuthLoadingState) {
    LoadingOverlay.showLoading(
      context,
      message: state.message ?? 'Signing in...',
    );
  } else if (state is LoginSuccessState) {
    LoadingOverlay.showSuccess(
      context,
      message: 'Welcome back!',
      onComplete: () {
        Navigator.pushReplacement(context, HomeScreen());
      },
    );
  } else if (state is AuthErrorState) {
    LoadingOverlay.showError(
      context,
      message: state.message,
      onComplete: () {
        // Handle error UI updates
      },
    );
  } else {
    LoadingOverlay.hide();
  }
}
```

## Utility Methods
```dart
// Check if overlay is currently showing
bool isShowing = LoadingOverlay.isShowing;

// Force hide any overlay
LoadingOverlay.hide();
```

## Visual Specifications
- **Background**: Transparent black (40% opacity)
- **Loader Size**: 80px diameter
- **Text Style**: 16px, medium weight, white color
- **Animation**: Fade in/out with 300ms duration
- **Logo Animation**: Stroke-to-fill with state-based colors

## Colors by State
- **Loading**: Teal (`AppColors.tealColor`)
- **Success**: Teal with scale effect
- **Error**: Red with shake animation

## Haptic Feedback
- **Success**: Medium impact → Light impact → Selection click
- **Error**: Heavy impact
- **Loading**: No haptic (continuous state)

## Notes
- The overlay is automatically managed and prevents multiple overlays
- Full-screen overlay blocks all user interaction during display
- Text is displayed directly without styled containers for clean appearance
- System integrates seamlessly with existing dark theme design 