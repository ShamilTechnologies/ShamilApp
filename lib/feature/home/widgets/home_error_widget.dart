import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For fallback colors

class HomeErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool showRetryButton;

  const HomeErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 50),
            const Gap(16),
            Text(
              "Oops! Something went wrong.",
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              message,
              // Use theme secondary color if available, otherwise fallback
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton) ...[
              const Gap(24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
                onPressed: onRetry, // Call the provided callback
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
