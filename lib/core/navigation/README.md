# Service Provider Navigation System

This directory contains the unified navigation system for service providers throughout the app. It provides consistent navigation patterns and centralizes routing logic.

## Overview

The navigation system connects **any service provider card press** to the appropriate destination screens with proper BLoC integration and data passing.

## Key Components

### 1. ServiceProviderNavigation (`service_provider_navigation.dart`)
Main navigation utility class providing:
- **Universal provider navigation** - Navigate to provider details from any card
- **Filtered browsing** - Open providers screen with category/city/search filters
- **Convenience methods** - One-line navigation setup for common patterns
- **Consistent BLoC integration** - Automatic FavoritesBloc passing

### 2. Navigation Examples (`service_provider_navigation_examples.dart`)
Comprehensive examples showing:
- Simple card implementations
- Category and city navigation
- Custom navigation with business logic
- Animated cards with navigation
- List and grid patterns

## Usage Patterns

### Quick Provider Card Navigation
```dart
// Any service provider card can use this one-liner
onTap: ServiceProviderNavigation.createProviderCardNavigation(
  context,
  provider: provider,
  heroTagPrefix: 'your_prefix',
),
```

### Category Navigation
```dart
// Navigate to providers filtered by category
onPressed: ServiceProviderNavigation.createCategoryNavigation(
  context,
  'Fitness',
),
```

### Search Navigation
```dart
// Navigate to providers with search query
onPressed: ServiceProviderNavigation.createSearchNavigation(
  context,
  'gym near me',
),
```

### "See All" Navigation
```dart
// Perfect for section "See All" buttons
ServiceProviderNavigation.navigateToSeeAll(
  context,
  sectionTitle: 'Fitness & Gym',
  currentCity: 'Cairo',
);
```

## Integration Points

### Home Screen
- **See All buttons** → Modern providers screen with filters
- **Provider cards** → Provider detail screen
- **Category cards** → Filtered providers screen

### Favorites Screen
- **Favorite cards** → Provider detail screen with proper BLoC context

### Search Results
- **Search result cards** → Provider detail screen
- **Quick category filters** → Filtered providers screen

### Modern Providers Screen
- **Provider cards** → Provider detail screen
- **Advanced filtering** → Refreshed results with filters

## Technical Details

### BLoC Integration
All navigation automatically includes:
```dart
BlocProvider.value(
  value: BlocProvider.of<FavoritesBloc>(context),
  child: DestinationScreen(...),
)
```

### Hero Animations
Each navigation uses unique hero tags:
- Format: `{prefix}_{providerId}`
- Ensures smooth transitions between screens

### Data Passing
- Provider detail screens receive `ServiceProviderDisplayModel` for instant loading
- Fallback to ID-based loading if data not available

## Screen Destinations

### 1. ServiceProviderDetailScreen
**When**: User taps any provider card
**Features**:
- Full provider information
- Services and subscription plans
- Booking and configuration options
- Contact information and location

### 2. ModernProvidersScreen
**When**: User wants to browse providers
**Features**:
- Advanced search and filtering
- Category and city filters
- Featured providers toggle
- Grid layout with animations

## Navigation Flow Examples

### 1. Home → Category → Provider Details
```
Home Screen
  ↓ (User taps "See All Fitness")
Modern Providers Screen (filtered by Fitness)
  ↓ (User taps provider card)
Provider Detail Screen
```

### 2. Search → Filtered Results → Provider Details
```
Home Screen
  ↓ (User searches "gym")
Modern Providers Screen (search results)
  ↓ (User applies city filter)
Modern Providers Screen (filtered)
  ↓ (User taps provider card)
Provider Detail Screen
```

### 3. Favorites → Provider Details
```
Favorites Screen
  ↓ (User taps favorite card)
Provider Detail Screen
```

## Customization

### Adding New Navigation Sources
1. Import the navigation utility:
```dart
import 'package:shamil_mobile_app/core/navigation/service_provider_navigation.dart';
```

2. Use convenience methods for common patterns:
```dart
// For provider cards
onTap: ServiceProviderNavigation.createProviderCardNavigation(
  context,
  provider: provider,
  heroTagPrefix: 'unique_prefix',
)

// For categories
onPressed: ServiceProviderNavigation.createCategoryNavigation(context, category)

// For custom logic
onTap: () async {
  // Your custom logic here
  await ServiceProviderNavigation.navigateToProviderDetail(
    context,
    providerId: provider.id,
    heroTag: 'custom_${provider.id}',
    initialProviderData: provider,
  );
}
```

### Adding New Filter Types
1. Extend `ServiceProviderNavigation.navigateToProviders()` parameters
2. Update `ModernProvidersScreen` to handle new filter types
3. Add convenience methods as needed

### Custom Hero Tags
Use descriptive prefixes to avoid conflicts:
- `home_featured_` - Home screen featured section
- `search_result_` - Search results
- `favorites_` - Favorites screen
- `category_fitness_` - Category-specific listings

## Testing Navigation

### Unit Tests
Test navigation utility methods:
```dart
test('createProviderCardNavigation returns valid callback', () {
  final callback = ServiceProviderNavigation.createProviderCardNavigation(
    context,
    provider: mockProvider,
    heroTagPrefix: 'test',
  );
  expect(callback, isA<VoidCallback>());
});
```

### Widget Tests
Test that cards have proper navigation:
```dart
testWidgets('provider card navigates on tap', (tester) async {
  await tester.pumpWidget(TestWidget(
    child: ExampleProviderCard(provider: mockProvider),
  ));
  
  await tester.tap(find.byType(ExampleProviderCard));
  await tester.pumpAndSettle();
  
  expect(find.byType(ServiceProviderDetailScreen), findsOneWidget);
});
```

## Performance Considerations

### Navigation Optimization
- Uses BlocProvider.value to avoid bloc recreation
- Passes initial data to prevent loading delays
- Lazy loading for filtered screens

### Memory Management
- Proper hero tag uniqueness prevents memory leaks
- Automatic disposal of screen resources
- Efficient data passing without duplication

## Troubleshooting

### Common Issues
1. **BLoC not found**: Ensure FavoritesBloc is provided in parent widget tree
2. **Hero animation errors**: Check hero tag uniqueness
3. **Navigation not working**: Verify context is valid and widget is mounted

### Debug Tips
- Use descriptive hero tag prefixes for easier debugging
- Check console for navigation errors
- Verify provider data structure matches expectations

---

This navigation system ensures that **any service provider card press** throughout the app leads to a consistent, smooth navigation experience with proper data flow and BLoC integration. 