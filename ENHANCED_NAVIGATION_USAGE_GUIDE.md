# Enhanced Navigation System Usage Guide

## Overview

The Enhanced Navigation System provides smooth, animated transitions throughout the app with specialized support for authentication flows and general navigation patterns.

## Features

✅ **Smooth Animations**: Custom transitions with easing curves  
✅ **Haptic Feedback**: Built-in haptic feedback for better UX  
✅ **Auth-Specific Navigation**: Specialized flows for sign-in, register, forgot password  
✅ **Multiple Transition Types**: Fade, slide, scale, and custom transitions  
✅ **Extension Methods**: Convenient context extensions for easy usage  
✅ **Global Navigation**: Consistent navigation patterns across the app  

## Quick Usage

### Using Extension Methods (Recommended)

```dart
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';

// Auth Navigation - with specialized animations
context.toSignIn(const CreativeSignInView());
context.toRegister(const ModernRegisterView());
context.toForgotPassword(const ForgotPasswordView());

// Global Navigation - for general app navigation
context.pushFade(const ProfileScreen());
context.pushSlideRight(const SettingsScreen());
context.pushSlideUp(const BottomSheetScreen());
context.pushScale(const DialogScreen());
```

### Using Static Methods

```dart
// Auth Navigation
AuthNavigation.toSignIn(context, const CreativeSignInView());
AuthNavigation.toRegister(context, const ModernRegisterView());
AuthNavigation.toForgotPassword(context, const ForgotPasswordView());
AuthNavigation.toMainApp(context, const MainNavigationView());

// Global Navigation
GlobalNavigation.pushFade(context, const NextScreen());
GlobalNavigation.pushSlideRight(context, const NextScreen());
GlobalNavigation.replaceFade(context, const NextScreen());
GlobalNavigation.clearAndNavigate(context, const NextScreen());

// Modal Navigation
ModalNavigation.showBottomSheet(context, const MyBottomSheet());
ModalNavigation.showDialog(context, const MyDialog());
```

## Navigation Types

### 1. Auth Navigation
Specialized for authentication flow with consistent branding and UX:

```dart
// Navigate to sign-in with left slide + fade
AuthNavigation.toSignIn(context, const CreativeSignInView());

// Navigate to register with right slide + fade  
AuthNavigation.toRegister(context, const ModernRegisterView());

// Navigate to forgot password with gentle fade-slide
AuthNavigation.toForgotPassword(context, const ForgotPasswordView());

// Navigate to main app after successful auth with special transition
AuthNavigation.toMainApp(context, const MainNavigationView());

// Back navigation with haptic feedback
AuthNavigation.back(context);
```

### 2. Global Navigation
For general app navigation with various transition types:

```dart
// Fade transition - elegant and subtle
GlobalNavigation.pushFade(context, const NextScreen());

// Slide from right - iOS-style navigation
GlobalNavigation.pushSlideRight(context, const NextScreen());

// Slide from bottom - modal-style presentation
GlobalNavigation.pushSlideUp(context, const NextScreen());

// Scale transition - attention-grabbing
GlobalNavigation.pushScale(context, const NextScreen());

// Replace current screen with fade
GlobalNavigation.replaceFade(context, const NextScreen());

// Replace with slide in specific direction
GlobalNavigation.replaceSlide(
  context, 
  const NextScreen(),
  direction: SlideDirection.left,
);

// Clear navigation stack and navigate
GlobalNavigation.clearAndNavigate(context, const HomeScreen());
```

### 3. Modal Navigation
For overlays, bottom sheets, and dialogs:

```dart
// Bottom sheet with smooth animation
ModalNavigation.showBottomSheet(
  context,
  const MyBottomSheet(),
  isDismissible: true,
  enableDrag: true,
);

// Dialog with scale animation
ModalNavigation.showDialog(
  context,
  const MyDialog(),
  barrierDismissible: true,
);
```

## Animation Details

### Auth Transitions
- **Sign In**: Left slide with fade overlay
- **Register**: Right slide with fade overlay  
- **Forgot Password**: Gentle upward slide with fade
- **Success**: Scale + fade with back-easing

### Global Transitions
- **Fade**: Simple opacity transition
- **Slide Right**: Horizontal slide with secondary animation
- **Slide Up**: Vertical slide from bottom
- **Scale**: Scale from center with back-easing curve

### Timing
- **Fast**: 300ms - For quick interactions
- **Normal**: 500ms - Standard navigation
- **Slow**: 800ms - Success/completion flows

## Implementation Examples

### 1. Auth Flow Implementation

```dart
class CreativeSignInView extends StatelessWidget {
  void _navigateToRegister() {
    // Smooth slide transition to register
    context.toRegister(const ModernRegisterView());
  }

  void _navigateToForgotPassword() {
    // Gentle push transition to forgot password
    context.toForgotPassword(const ForgotPasswordView());
  }
}
```

### 2. Main App Navigation

```dart
class HomeScreen extends StatelessWidget {
  void _openProfile() {
    // Fade transition to profile
    context.pushFade(const ProfileScreen());
  }

  void _openSettings() {
    // iOS-style slide transition
    context.pushSlideRight(const SettingsScreen());
  }

  void _showFilterSheet() {
    // Bottom sheet modal
    ModalNavigation.showBottomSheet(
      context,
      const FilterBottomSheet(),
    );
  }
}
```

### 3. Custom Transition Directions

```dart
// Slide from different directions
GlobalNavigation.replaceSlide(
  context,
  const NextScreen(),
  direction: SlideDirection.left,   // or right, up, down
);
```

## Migration from Old Navigation

### Before (Old System)
```dart
push(context, const NextScreen());
pushReplacement(context, const NextScreen());
pushAndRemoveUntil(context, const NextScreen());
```

### After (Enhanced System)
```dart
context.pushFade(const NextScreen());
context.toSignIn(const NextScreen());
GlobalNavigation.clearAndNavigate(context, const NextScreen());
```

## Best Practices

### 1. Use Extension Methods
```dart
// ✅ Preferred - clean and readable
context.pushFade(const NextScreen());

// ❌ Avoid - verbose
GlobalNavigation.pushFade(context, const NextScreen());
```

### 2. Choose Appropriate Transitions
```dart
// ✅ Auth flow - use auth navigation
context.toSignIn(const SignInScreen());

// ✅ General navigation - use appropriate transition
context.pushSlideRight(const DetailScreen());

// ✅ Modals - use modal navigation
ModalNavigation.showBottomSheet(context, const FilterSheet());
```

### 3. Maintain Consistency
- Use auth navigation for all auth-related screens
- Use consistent transitions for similar interaction patterns
- Reserve special transitions (scale, etc.) for important actions

### 4. Performance Considerations
- Animations are optimized with proper curves and timing
- Haptic feedback is automatically included
- Memory management is handled internally

## Advanced Usage

### Custom Return Types
```dart
// Navigation with return values
final result = await context.pushFade<String>(const InputScreen());
if (result != null) {
  print('User entered: $result');
}
```

### Conditional Navigation
```dart
void handleNavigation() {
  if (user.isAuthenticated) {
    context.pushFade(const DashboardScreen());
  } else {
    context.toSignIn(const SignInScreen());
  }
}
```

## Current Implementation Status

✅ **Auth Screens Updated**:
- `CreativeSignInView` - Using enhanced auth navigation
- `ForgotPasswordView` - Using enhanced auth navigation  
- `ModernRegisterView` - Using enhanced auth navigation

✅ **System Features**:
- Smooth slide transitions for auth flow
- Haptic feedback on all navigation
- Proper animation timing and curves
- Extension methods for easy usage

## Future Enhancements

🔄 **Planned Additions**:
- Hero animations for shared elements
- Custom transition builders
- Navigation analytics
- Accessibility improvements
- Performance monitoring

---

**Note**: This enhanced navigation system maintains backward compatibility with existing navigation while providing smooth, modern transitions throughout the app. The auth flow now has consistent, branded animations that create a premium user experience. 