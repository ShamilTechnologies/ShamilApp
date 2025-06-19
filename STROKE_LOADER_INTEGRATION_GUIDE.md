# Global Stroke Loader Integration Guide

## Overview
Successfully integrated a global stroke-to-fill logo loader that automatically shows during `AuthLoadingState` across all authentication flows.

## Components Created

### 1. **GlobalStrokeLoader Widget**
```dart
// Available sizes and configurations
GlobalStrokeLoader.small()     // 24px - for buttons
GlobalStrokeLoader.medium()    // 48px - for cards
GlobalStrokeLoader.large()     // 120px - for screens
GlobalStrokeLoader.overlay()   // 100px - for overlays

// Custom configuration
GlobalStrokeLoader(
  size: 80.0,
  color: AppColors.tealColor,
  duration: Duration(milliseconds: 2000),
  showBackground: true,
)
```

### 2. **AuthLoadingWrapper Widget**
Automatically shows stroke loader during `AuthLoadingState`:
```dart
AuthLoadingWrapper(
  customMessage: 'Signing in...',
  child: YourContent(),
)
```

### 3. **AuthLoadingMixin**
Provides easy integration methods for any auth screen:
```dart
class _LoginViewState extends State<LoginView> with AuthLoadingMixin<LoginView> {
  @override
  Widget build(BuildContext context) {
    return withAuthLoading(
      YourContent(),
      customMessage: 'Signing in to your account...',
    );
  }
}
```

## Usage Examples

### **Current: Premium Login View**
```dart
class _PremiumLoginViewState extends State<PremiumLoginView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          body: AuthLoadingWrapper(
            customMessage: _getLoadingMessage(state),
            child: PremiumAuthBackground(
              child: YourLoginForm(),
            ),
          ),
        );
      },
    );
  }
  
  String? _getLoadingMessage(AuthState state) {
    if (state is AuthLoadingState) {
      return state.message ?? 'Signing in to your account...';
    }
    return null;
  }
}
```

### 🔄 **Register View Integration**
```dart
class _RegisterViewState extends State<RegisterView> with AuthLoadingMixin<RegisterView> {
  @override
  Widget build(BuildContext context) {
    return withAuthLoading(
      Scaffold(
        body: YourRegisterForm(),
      ),
      // Automatic message: "Creating your account..."
    );
  }
}
```

### 🔄 **Upload ID View Integration**
```dart
class _UploadIdViewState extends State<UploadIdView> with AuthLoadingMixin<UploadIdView> {
  @override
  Widget build(BuildContext context) {
    return withAuthLoading(
      YourUploadForm(),
      customMessage: 'Uploading your documents...',
    );
  }
}
```

### 🔄 **Forgot Password Integration**
```dart
class _ForgotPasswordViewState extends State<ForgotPasswordView> with AuthLoadingMixin<ForgotPasswordView> {
  @override
  Widget build(BuildContext context) {
    return withAuthLoading(
      YourResetForm(),
      // Automatic message: "Sending reset email..."
    );
  }
}
```

## Button Integration

### **Premium Auth Button**
Already integrated with stroke loader:
```dart
PremiumAuthButton(
  text: isLoading ? 'Signing in...' : 'Sign In',
  isLoading: isLoading,
  onPressed: onPressed,
)
// Shows GlobalStrokeLoader.small() when loading
```

## Manual Control

### **Show/Hide Programmatically**
```dart
// Using LoaderHelper
LoaderHelper.showOverlay(context, message: 'Processing...');
LoaderHelper.hideOverlay(context);

// Using AuthLoadingMixin
showAuthLoading(context, message: 'Custom operation...');
hideAuthLoading(context);
```

## AuthBloc Integration

### **Loading State Messages**
The `AuthLoadingState` can include contextual messages:
```dart
// In AuthBloc
emit(const AuthLoadingState(message: 'Verifying credentials...'));
emit(const AuthLoadingState(message: 'Creating user profile...'));
emit(const AuthLoadingState(message: 'Uploading documents...'));
```

### **Automatic Message Detection**
The mixin automatically provides contextual messages based on screen type:
- **Login screens**: "Signing in to your account..."
- **Register screens**: "Creating your account..."
- **Upload screens**: "Uploading your documents..."
- **Reset screens**: "Sending reset email..."
- **Profile screens**: "Updating your profile..."

## Usage Patterns

### **Pattern 1: Wrapper Integration**
Best for screens that need full overlay loading:
```dart
AuthLoadingWrapper(
  customMessage: 'Your message',
  child: YourContent(),
)
```

### **Pattern 2: Mixin Integration**
Best for reusable auth screen functionality:
```dart
class _YourState extends State<YourWidget> with AuthLoadingMixin<YourWidget> {
  Widget build(BuildContext context) {
    return withAuthLoading(YourContent());
  }
}
```

### **Pattern 3: Extension Integration**
Quick integration with existing widgets:
```dart
YourWidget().withAuthLoader(
  customMessage: 'Loading...',
)
```

## State-Specific Loading Messages

### **Custom State Mapping**
```dart
withAuthLoading(
  YourContent(),
  stateMessages: {
    AuthLoadingState: 'Custom loading message...',
  },
)
```

## Visual Hierarchy

### **Loading States Priority**
1. **Overlay Loader**: Full-screen operations (login, register, upload)
2. **Button Loader**: Action-specific feedback
3. **Inline Loader**: Component-level loading

### **Consistent Design**
- **Colors**: Inherits from AppColors.tealColor
- **Animation**: 2-second stroke-to-fill cycle
- **Background**: Matching splash screen aesthetic
- **Typography**: BalooBhaijaan2 font family

## Performance Considerations

### **Optimizations Implemented**
- **RepaintBoundary**: Reduces rebuild scope
- **Single Ticker**: Efficient animation management
- **Conditional Rendering**: Only shows when needed
- **Memory Management**: Proper disposal of controllers

### **Best Practices**
- Use appropriate size variants for context
- Provide meaningful loading messages
- Avoid nested loading overlays
- Test on different screen sizes

## Integration Checklist

### **For New Auth Screens**
- [ ] Import AuthLoadingWrapper or use AuthLoadingMixin
- [ ] Wrap main content with loading functionality
- [ ] Provide contextual loading messages
- [ ] Test loading states with AuthBloc
- [ ] Verify visual consistency

### **For Existing Auth Screens**
- [ ] Replace CircularProgressIndicator with GlobalStrokeLoader
- [ ] Update button loading states
- [ ] Add AuthLoadingWrapper around main content
- [ ] Test state transitions
- [ ] Verify no duplicate loading indicators

## Future Enhancements

### **Potential Improvements**
1. **Localization**: i18n support for loading messages
2. **Haptic Feedback**: Subtle vibrations during state changes
3. **Progress Indicators**: Step-by-step upload progress
4. **Error Animation**: Failure state visual feedback
5. **Accessibility**: Screen reader announcements

## Integration Complete ✅

The stroke loader is now fully integrated with the AuthBloc system and will automatically show during all `AuthLoadingState` emissions, providing a consistent premium loading experience across the entire authentication flow. 