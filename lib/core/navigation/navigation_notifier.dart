// lib/core/navigation/navigation_notifier.dart
import 'package:flutter/foundation.dart';

class NavigationNotifier extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // Method to be called by other widgets to request a tab change
  void selectTab(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners(); // Notify listeners (like MainNavigationView) about the change
    }
  }

  // Internal method for MainNavigationView to update its own state
  // This might not be strictly necessary if MainNavigationView directly listens
  // but can be useful for keeping state consistent.
  void internalSetIndex(int index) {
     _selectedIndex = index;
     // No need to notifyListeners here if only MainNavigationView uses this
  }
}