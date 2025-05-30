import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/navigation/service_provider_navigation.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

/// Examples of how to use ServiceProviderNavigation
/// This file demonstrates various ways to connect any service provider card
/// or component to navigation functionality.

/// Example 1: Simple provider card with navigation
class ExampleProviderCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;

  const ExampleProviderCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Using the convenience method to create navigation
      onTap: ServiceProviderNavigation.createProviderCardNavigation(
        context,
        provider: provider,
        heroTagPrefix: 'example',
      ),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: provider.imageUrl != null
                ? NetworkImage(provider.imageUrl!)
                : null,
            child: provider.imageUrl == null ? Icon(Icons.business) : null,
          ),
          title: Text(provider.businessName),
          subtitle: Text(provider.businessCategory),
          trailing: Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}

/// Example 2: Category button with navigation
class ExampleCategoryButton extends StatelessWidget {
  final String categoryName;
  final IconData icon;

  const ExampleCategoryButton({
    super.key,
    required this.categoryName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      // Using the convenience method for category navigation
      onPressed: ServiceProviderNavigation.createCategoryNavigation(
        context,
        categoryName,
      ),
      icon: Icon(icon),
      label: Text(categoryName),
    );
  }
}

/// Example 3: Search button with predefined query
class ExampleSearchButton extends StatelessWidget {
  final String searchQuery;

  const ExampleSearchButton({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      // Using the convenience method for search navigation
      onPressed: ServiceProviderNavigation.createSearchNavigation(
        context,
        searchQuery,
      ),
      icon: Icon(Icons.search),
      label: Text('Search "$searchQuery"'),
    );
  }
}

/// Example 4: City selector with navigation
class ExampleCitySelector extends StatelessWidget {
  final List<String> cities = [
    'Cairo',
    'Alexandria',
    'Giza',
    'Sharm El Sheikh',
    'Hurghada',
  ];

  ExampleCitySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Browse by City:', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: cities.map((city) {
            return ActionChip(
              label: Text(city),
              // Using the convenience method for city navigation
              onPressed: ServiceProviderNavigation.createCityNavigation(
                context,
                city,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Example 5: Manual navigation with custom logic
class ExampleCustomNavigation extends StatelessWidget {
  final ServiceProviderDisplayModel provider;

  const ExampleCustomNavigation({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          // Example: Add custom logic before navigation
          bool shouldNavigate = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Navigate to ${provider.businessName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Yes'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldNavigate) {
            // Use the navigation utility after custom logic
            await ServiceProviderNavigation.navigateToProviderDetail(
              context,
              providerId: provider.id,
              heroTag: 'custom_${provider.id}',
              initialProviderData: provider,
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.businessName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 4),
              Text(
                provider.businessCategory,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Tap for custom navigation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 6: List item with direct navigation
class ExampleListItem extends StatelessWidget {
  final ServiceProviderDisplayModel provider;

  const ExampleListItem({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: provider.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(provider.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: provider.imageUrl == null ? Colors.grey[300] : null,
        ),
        child: provider.imageUrl == null
            ? Icon(Icons.business, color: Colors.grey[600])
            : null,
      ),
      title: Text(provider.businessName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(provider.businessCategory),
          if (provider.averageRating > 0)
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.orange),
                Text(' ${provider.averageRating.toStringAsFixed(1)}'),
              ],
            ),
        ],
      ),
      trailing: Icon(Icons.chevron_right),
      // Direct navigation without convenience method
      onTap: () {
        ServiceProviderNavigation.navigateToProviderDetail(
          context,
          providerId: provider.id,
          heroTag: 'list_${provider.id}',
          initialProviderData: provider,
        );
      },
    );
  }
}

/// Example 7: Grid item with animation
class ExampleGridItem extends StatefulWidget {
  final ServiceProviderDisplayModel provider;

  const ExampleGridItem({
    super.key,
    required this.provider,
  });

  @override
  State<ExampleGridItem> createState() => _ExampleGridItemState();
}

class _ExampleGridItemState extends State<ExampleGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: ServiceProviderNavigation.createProviderCardNavigation(
        context,
        provider: widget.provider,
        heroTagPrefix: 'grid',
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        image: widget.provider.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.provider.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: widget.provider.imageUrl == null
                            ? Colors.grey[300]
                            : null,
                      ),
                      child: widget.provider.imageUrl == null
                          ? Center(
                              child: Icon(
                                Icons.business,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.provider.businessName,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.provider.businessCategory,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
