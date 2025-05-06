// lib/feature/details/views/service_provider_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data'; // For Uint8List used in transparentImageData

// Core utilities and constants
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // For amenity icons
import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // For transparentImageData
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'; // Assuming buildProfilePlaceholder or other placeholders might be used

// Models
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Blocs
import 'package:shamil_mobile_app/feature/details/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';

// Repository
import 'package:shamil_mobile_app/feature/reservation/repository/reservation_repository.dart'; // Import repository

// Widgets
import 'package:shamil_mobile_app/feature/details/widgets/animated_swipe_up_bar.dart';
// Use alias to avoid potential naming conflicts if OptionsBottomSheetContent is defined elsewhere
import 'package:shamil_mobile_app/feature/details/widgets/options_bottom_sheet.dart'
    as options_sheet;

/// Displays the detailed view of a service provider.
///
/// Fetches detailed data using [ServiceProviderDetailBloc] and allows users
/// to view options (subscriptions/reservations) via a bottom sheet.
class ServiceProviderDetailScreen extends StatelessWidget {
  /// The unique ID of the provider to display.
  final String providerId;

  /// An optional initial image URL, often passed from the list view for Hero animation.
  final String? initialImageUrl;

  /// Optional initial display data, passed from the list view for faster initial rendering.
  final ServiceProviderDisplayModel? initialProviderData;

  /// The unique tag for the Hero animation transition of the main image.
  final String heroTag;

  /// Creates the detail screen.
  ///
  /// Requires [providerId] and [heroTag].
  const ServiceProviderDetailScreen({
    super.key,
    required this.providerId,
    this.initialImageUrl,
    this.initialProviderData,
    required this.heroTag, // Accept the unique heroTag
  });

  // --- Styling Constants ---
  static final BorderRadius _borderRadius = BorderRadius.circular(12.0);
  static const EdgeInsets _imagePadding =
      EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0);
  static const EdgeInsets _contentPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
  // Aspect ratio for the main header image (e.g., 1.0 for square, 16/9 for landscape)
  static const double _imageAspectRatio = 1.0;

  /// Shows the modal bottom sheet containing reservation and/or subscription options.
  /// Correctly provides scoped Blocs and reads the necessary repository.
  void _showOptionsBottomSheet(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    bool isHybrid = provider.pricingModel == PricingModel.hybrid;

    showModalBottomSheet(
      context: context, // Use context from the DetailScreen build method
      isScrollControlled: true, // Allows sheet to take more height
      backgroundColor: Colors.transparent, // Sheet container handles background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Provide necessary Blocs scoped to the bottom sheet
        // This ensures the OptionsBottomSheetContent and its children can access them
        // Assumes ReservationRepository is provided higher up in the widget tree (e.g., main.dart)
        return MultiBlocProvider(
          providers: [
            // Provides SubscriptionBloc for subscription actions within the sheet
            BlocProvider<SubscriptionBloc>(
              create: (_) => SubscriptionBloc(),
              // TODO: Inject dependencies like PaymentService if needed
            ),
            // Provides ReservationBloc, initialized with the specific provider and repository
            BlocProvider<ReservationBloc>(
              create: (blocContext) => ReservationBloc(
                // Use blocContext here
                provider:
                    provider, // Pass the specific provider data for this sheet
                // Read the SINGLETON repository instance from the context above the sheet
                reservationRepository:
                    blocContext.read<ReservationRepository>(),
              ),
            ),
            // Provide SocialBloc if attendee dialogs need it directly (assuming it's provided higher up)
            // Example: BlocProvider.value(value: context.read<SocialBloc>()),
          ],
          // DraggableScrollableSheet allows the sheet height to be adjusted by dragging
          child: DraggableScrollableSheet(
            initialChildSize: 0.6, // Initial height fraction
            minChildSize: 0.3, // Minimum height fraction
            maxChildSize: 0.9, // Maximum height fraction
            expand: false, // Don't expand to full screen initially
            builder: (_, scrollController) {
              // Container for sheet styling (background, corners, shadow)
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                // The actual content widget for the bottom sheet
                child: options_sheet.OptionsBottomSheetContent(
                  provider: provider,
                  scrollController: scrollController, // Pass scroll controller
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Provide the ServiceProviderDetailBloc at the screen level
    // It will be created once and available to all descendants.
    return BlocProvider(
      create: (context) => ServiceProviderDetailBloc()
        // Immediately trigger loading the details when the Bloc is created
        ..add(LoadServiceProviderDetails(providerId: providerId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // Use Stack to overlay elements like the swipe bar and buttons
        body: Stack(
          children: [
            // --- Main Content Area ---
            // BlocConsumer listens to state changes for rebuilding (builder)
            // and for side effects (listener, e.g., showing snackbars).
            BlocConsumer<ServiceProviderDetailBloc, ServiceProviderDetailState>(
              listener: (context, state) {
                // Optional: Handle side effects like showing snackbars for errors
                // that don't require rebuilding the whole UI (e.g., favorite toggle failure)
                // if (state is ServiceProviderDetailActionError) {
                //   showGlobalSnackBar(context, state.message, isError: true);
                // }
              },
              builder: (context, state) {
                // --- Determine Data Source and State ---
                ServiceProviderModel? detailedProvider;
                bool isFullyLoaded = false;
                bool isFavorite = false; // Default favorite state

                if (state is ServiceProviderDetailLoaded) {
                  // Data is fully loaded from the Bloc
                  detailedProvider = state.provider;
                  isFullyLoaded = true;
                  isFavorite =
                      state.isFavorite; // Get favorite status from loaded state
                } else if (initialProviderData != null) {
                  // Use initial data passed during navigation while loading full details
                  isFavorite = initialProviderData!.isFavorite;
                }

                // --- Extract Data Safely ---
                // Use loaded data if available, fallback to initial data, then to 'Loading...'
                final providerName = detailedProvider?.businessName ??
                    initialProviderData?.businessName ??
                    'Loading...';
                // Use loaded image URL, fallback to initial display URL, then to initial passed URL
                final providerImageUrl = detailedProvider?.mainImageUrl ??
                    initialProviderData?.imageUrl ??
                    initialImageUrl;
                final providerLogoUrl =
                    detailedProvider?.logoUrl ?? initialProviderData?.logoUrl;
                final providerRating = detailedProvider?.rating ??
                    initialProviderData?.rating ??
                    0.0;
                final providerRatingCount = detailedProvider?.ratingCount ??
                    initialProviderData?.reviewCount ??
                    0;
                final providerCity =
                    detailedProvider?.city ?? initialProviderData?.city ?? '';
                final providerGovernorate =
                    detailedProvider?.governorate; // Can be null
                final providerDescription =
                    detailedProvider?.businessDescription; // Can be null
                final providerAmenities =
                    detailedProvider?.amenities; // Can be null or empty

                // --- Render UI Based on State ---

                // 1. Loading State: Show shimmer placeholder if no initial data
                if (!isFullyLoaded &&
                    initialProviderData == null &&
                    (state is ServiceProviderDetailLoading ||
                        state is ServiceProviderDetailInitial)) {
                  return _buildLoadingShimmer(
                      context, theme, initialImageUrl, heroTag);
                }
                // 2. Error State: Show error message and retry button
                else if (state is ServiceProviderDetailError) {
                  return _buildErrorWidget(context, theme, state.message);
                }
                // 3. Loaded State (or Initial Data Available): Show content
                else {
                  return _buildStackLayoutContent(
                    context, theme,
                    isFullyLoaded:
                        isFullyLoaded, // Indicates if full details are loaded
                    isFavorite: isFavorite, // Current favorite status
                    providerId:
                        providerId, // Needed for actions like favorite toggle
                    heroTag: heroTag, // Use the passed heroTag
                    providerName: providerName,
                    providerImageUrl: providerImageUrl,
                    providerLogoUrl: providerLogoUrl,
                    providerRating: providerRating,
                    providerRatingCount: providerRatingCount,
                    providerCity: providerCity,
                    providerGovernorate: providerGovernorate,
                    providerDescription: providerDescription,
                    providerAmenities: providerAmenities,
                    // Pass the fully loaded provider data if available (needed for bottom sheet)
                    detailedProviderData: detailedProvider,
                  );
                }
              },
            ),

            // --- Animated Swipe-Up Bar ---
            // Shown only when detailed data is loaded
            BlocBuilder<ServiceProviderDetailBloc, ServiceProviderDetailState>(
              builder: (context, state) {
                // Show the bar only when the detailed provider data is successfully loaded
                if (state is ServiceProviderDetailLoaded) {
                  return Positioned(
                    bottom: 0, left: 0, right: 0,
                    // Adjust padding to account for system navigation bars/notches
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom),
                      // Use the fully loaded provider data to show the sheet
                      child: AnimatedSwipeUpBar(
                        title: "View Options & Book",
                        onTap: () => _showOptionsBottomSheet(
                            context, theme, state.provider),
                      ),
                    ),
                  );
                } else {
                  // Hide the bar if data is not loaded or in error state
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builder Helper Methods ---

  /// Builds the shimmer loading placeholder UI.
  Widget _buildLoadingShimmer(BuildContext context, ThemeData theme,
      String? imageUrlForHero, String heroTag) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageWidth =
        screenWidth - _imagePadding.left - _imagePadding.right;
    final double imageHeight = imageWidth / _imageAspectRatio;
    final shimmerBaseColor = Colors.grey.shade300; // Standard shimmer colors
    final shimmerHighlightColor = Colors.grey.shade100;
    final shimmerContentColor = Colors.white; // Color of the shimmer shapes

    return ListView(
      // Use ListView to allow potential scrolling if shimmer content exceeds screen
      padding: EdgeInsets.zero, // Remove default padding
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling for shimmer
      children: [
        // Shimmer for Header Image Area (includes Hero)
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top) +
              _imagePadding,
          child: Hero(
            tag: heroTag, // Use the unique hero tag
            // Placeholder builder for Hero transition (optional, shows during animation)
            placeholderBuilder: (context, heroSize, child) {
              return SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Shimmer.fromColors(
                  baseColor: shimmerBaseColor,
                  highlightColor: shimmerHighlightColor,
                  child: ClipRRect(
                      borderRadius: _borderRadius,
                      child: Container(color: shimmerContentColor)),
                ),
              );
            },
            // The actual shimmer effect for the image area
            child: ClipRRect(
              borderRadius: _borderRadius,
              child: SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Shimmer.fromColors(
                  baseColor: shimmerBaseColor,
                  highlightColor: shimmerHighlightColor,
                  child: Container(
                    color: shimmerContentColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Shimmer for the rest of the content below the image
        Padding(
          padding: _contentPadding +
              const EdgeInsets.only(top: 24), // Padding for content
          child: Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Column(
              // Column for shimmer placeholders
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder for Title Row
                Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 8)),
                Container(
                    width: screenWidth * 0.7,
                    height: 18,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(
                    width: screenWidth * 0.5,
                    height: 18,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 16)),
                const Divider(color: AppColors.accentColor),
                const Gap(16),
                // Placeholder for Description Section
                Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 8)),
                Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(
                    width: screenWidth * 0.7,
                    height: 16,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 24)),
                // Placeholder for Facilities Section
                Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 16)),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: List.generate(
                    4,
                    (_) => Column(
                      children: [
                        Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                color: shimmerContentColor,
                                borderRadius: _borderRadius)),
                        const Gap(6),
                        Container(
                            width: 50,
                            height: 12,
                            decoration: BoxDecoration(
                                color: shimmerContentColor,
                                borderRadius: _borderRadius)),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                // Placeholder for Plans/Services Section
                Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 16)),
                Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 24)),
                // Placeholder for Reviews Section
                Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 16)),
                Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                        color: shimmerContentColor,
                        borderRadius: _borderRadius),
                    margin: const EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
        )
      ],
    );
  }

  /// Builds the main content layout using a Stack for overlaying elements.
  Widget _buildStackLayoutContent(
    BuildContext context,
    ThemeData theme, {
    required bool isFullyLoaded,
    required bool isFavorite,
    required String providerId,
    required String heroTag, // Accepts the unique hero tag
    required String providerName,
    required String? providerImageUrl,
    required String? providerLogoUrl,
    required double providerRating,
    required int providerRatingCount,
    required String providerCity,
    required String? providerGovernorate,
    required String? providerDescription,
    required List<String>? providerAmenities,
    required ServiceProviderModel? detailedProviderData, // Full data if loaded
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageWidth =
        screenWidth - _imagePadding.left - _imagePadding.right;
    final double imageHeight = imageWidth / _imageAspectRatio;
    final double topSafeArea = MediaQuery.of(context).padding.top;
    // Calculate the starting Y position for content below the image
    final double contentStartY =
        topSafeArea + imageHeight + _imagePadding.top + _imagePadding.bottom;
    // Build the title row widget separately for clarity
    Widget titleRowWidget = _buildTitleRowWidget(theme, providerName,
        providerRating, providerRatingCount, providerCity, providerGovernorate);

    return Stack(
      children: [
        // --- Scrollable Content Area ---
        // Positioned below the header image area
        Positioned.fill(
          top: contentStartY,
          child: Scrollbar(
            // Adds a scrollbar
            child: SingleChildScrollView(
              // Makes the content scrollable
              physics: const BouncingScrollPhysics(), // iOS-style bounce effect
              padding: EdgeInsets.only(
                  left: _contentPadding.left,
                  right: _contentPadding.right,
                  // Add bottom padding to prevent content from being hidden by the swipe bar
                  bottom: 80 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(24), // Space between image bottom and title row
                  titleRowWidget, // Display name, rating, location
                  const Gap(16),
                  const Divider(
                      color: AppColors.accentColor), // Visual separator
                  const Gap(16),

                  // Description Section
                  _buildSectionTitle(theme, "Description"),
                  const Gap(8),
                  // Use AnimatedSwitcher for smooth transition when description loads
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        isFullyLoaded // Show description only when fully loaded
                            ? _buildDescription(
                                theme, providerDescription ?? '')
                            // Show placeholder while loading full details
                            : Container(
                                key: const ValueKey('desc_shimmer'),
                                child: _buildShimmerPlaceholder(
                                    height: 60, width: double.infinity)),
                  ),
                  const Gap(24),

                  // Facilities Section
                  _buildSectionTitle(theme, "Facilities"),
                  const Gap(16),
                  // Use AnimatedSwitcher for smooth transition when facilities load
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        isFullyLoaded // Show facilities only when fully loaded
                            ? _buildFacilities(theme, providerAmenities ?? [])
                            // Show placeholder while loading full details
                            : Container(
                                key: const ValueKey('fac_shimmer'),
                                child: _buildShimmerPlaceholder(
                                    height: 75, width: double.infinity)),
                  ),
                  const Gap(24),

                  // Plans & Services Section (Placeholder)
                  _buildSectionTitle(theme, "Plans & Services"),
                  const Gap(8),
                  // Placeholder container hinting to swipe up
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.5),
                        borderRadius: _borderRadius),
                    child: Center(
                        child: Text("Swipe up or tap below to view options",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.secondaryColor))),
                  ),
                  const Gap(24),

                  // Reviews Section (Placeholder)
                  _buildSectionTitle(theme, "Reviews ($providerRatingCount)"),
                  const Gap(8),
                  // Placeholder container for reviews
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.5),
                        borderRadius: _borderRadius),
                    child: Center(
                        child: Text("(User Reviews will appear here)",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.secondaryColor))),
                  ),
                  // Add more sections as needed (e.g., Location Map, Contact Info)
                ],
              ),
            ),
          ),
        ),

        // --- Overlaid Header Image ---
        // Positioned at the top, respecting safe area
        Positioned(
          top: topSafeArea,
          left: 0,
          right: 0,
          child: Padding(
            padding: _imagePadding, // Padding around the image
            child: Hero(
              tag: heroTag, // Use the unique tag passed to the screen
              placeholderBuilder: (context, heroSize, child) {
                // Optional: Define a placeholder shown *during* the Hero transition
                return SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: ClipRRect(
                        borderRadius: _borderRadius,
                        child: Container(color: Colors.white)),
                  ),
                );
              },
              // The actual image widget that animates
              child: ClipRRect(
                borderRadius: _borderRadius,
                child: _buildHeaderImage(providerImageUrl,
                    aspectRatio: _imageAspectRatio),
              ),
            ),
          ),
        ),

        // --- Overlaid Logo (Optional) ---
        // Positioned near the bottom-left corner of the image
        if (providerLogoUrl != null && providerLogoUrl.isNotEmpty)
          Positioned(
            top: topSafeArea +
                _imagePadding.top +
                imageHeight -
                40 -
                8, // Adjust vertical position
            left: _imagePadding.left + 8, // Adjust horizontal position
            child: Container(
              padding:
                  const EdgeInsets.all(4), // Padding inside the logo background
              decoration: BoxDecoration(
                color: AppColors.white
                    .withOpacity(0.85), // Semi-transparent white background
                borderRadius: _borderRadius, // Rounded corners
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 3,
                      spreadRadius: 1)
                ], // Subtle shadow
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    4), // Slightly smaller radius for logo itself
                child: CachedNetworkImage(
                  // Use CachedNetworkImage for logo
                  imageUrl: providerLogoUrl, height: 40, width: 40,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      const SizedBox.shrink(), // Hide on error
                  placeholder: (context, url) =>
                      const SizedBox(width: 40, height: 40), // Placeholder size
                ),
              ),
            ),
          ),

        // --- Overlaid Back Button ---
        // Positioned at the top-left corner of the image area
        Positioned(
          top: topSafeArea + _imagePadding.top + 8,
          left: _imagePadding.left + 8,
          child: _buildOverlayButton(
            context: context, theme: theme,
            isFavorite: false, // Not a favorite button
            icon: Icons.arrow_back_ios_new, tooltip: 'Back',
            onTap: () => Navigator.pop(context), // Action to navigate back
          ),
        ),

        // --- Overlaid Favorite Button ---
        // Positioned near the bottom-right corner of the image area
        Positioned(
          top: topSafeArea +
              _imagePadding.top +
              imageHeight -
              38 -
              8, // Adjust vertical position
          right: _imagePadding.right + 8, // Adjust horizontal position
          child: _buildOverlayButton(
            context: context, theme: theme,
            isFavorite: isFavorite, // Pass current favorite status
            // Use filled heart if favorite, outline otherwise
            icon: isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            iconColor: isFavorite
                ? AppColors.redColor
                : null, // Red color when favorite
            tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
            onTap: () {
              // Dispatch event to toggle favorite status in the Bloc
              context.read<ServiceProviderDetailBloc>().add(
                  ToggleFavoriteStatus(
                      providerId: providerId, currentStatus: isFavorite));
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widget Implementations ---

  /// Builds the title row containing name, rating, and location.
  Widget _buildTitleRowWidget(ThemeData theme, String name, double rating,
      int ratingCount, String city, String? governorate) {
    String locationString =
        "$city${city.isNotEmpty && governorate != null ? ', ' : ''}${governorate ?? ''}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // Row for Name and Rating
          crossAxisAlignment: CrossAxisAlignment.start, // Align tops
          children: [
            Expanded(
              // Name takes available space
              child: Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
            ),
            const Gap(12), // Space
            // Rating display
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded,
                    size: 20, color: AppColors.yellowColor),
                const Gap(4),
                Text(
                  rating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor),
                ),
                const Gap(4),
                if (ratingCount > 0) // Show count only if > 0
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "($ratingCount)",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryColor),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Gap(8), // Space below name/rating row
        Row(
          // Row for Location and Map button
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.location_solid,
                size: 16, color: AppColors.secondaryColor),
            const Gap(6),
            Expanded(
              // Location text takes available space
              child: Text(
                locationString.isEmpty
                    ? "Location not available"
                    : locationString,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.secondaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8), // Space before map button
            // "Show Map" button (placeholder action)
            TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact),
              icon: Icon(Icons.map_outlined,
                  size: 18, color: AppColors.primaryColor),
              label: Text("Show Map",
                  style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              onPressed: () {
                /* TODO: Implement map opening logic */ print(
                    "Show Map Tapped");
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the description text widget.
  Widget _buildDescription(ThemeData theme, String description) {
    return Text(
      description.isEmpty ? "No description available." : description,
      style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryColor.withOpacity(0.9),
          height: 1.5), // Line height for readability
    );
  }

  /// Builds the facilities section using a Wrap layout.
  Widget _buildFacilities(ThemeData theme, List<String> amenities) {
    if (amenities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "No specific facilities listed.",
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.secondaryColor.withOpacity(0.7)),
        ),
      );
    }
    // Display icons in a Wrap layout
    return Wrap(
      spacing: 12.0, // Horizontal spacing
      runSpacing: 12.0, // Vertical spacing
      children: amenities.map((amenityName) {
        // Get the corresponding icon using the helper function
        final IconData icon = getIconForAmenity(amenityName);
        // Build the icon widget for each amenity
        return _buildFacilityIcon(theme, icon, amenityName);
      }).toList(),
    );
  }

  /// Builds a single facility icon with its label.
  Widget _buildFacilityIcon(ThemeData theme, IconData icon, String label) {
    return SizedBox(
      width: 75, // Fixed width for each icon container
      child: Column(
        children: [
          // Icon background container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.7), // Background color
              borderRadius: _borderRadius, // Rounded corners
            ),
            child:
                Icon(icon, color: AppColors.primaryColor, size: 24), // The icon
          ),
          const Gap(6), // Space between icon and label
          // Label text
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds a standard section title widget.
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.primaryColor),
    );
  }

  /// Builds the small, semi-transparent overlay buttons (Back, Favorite).
  Widget _buildOverlayButton({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
    required bool isFavorite, // Needed for favorite button state
  }) {
    final Color backgroundColor =
        AppColors.white.withOpacity(0.7); // Background color
    final Color defaultIconColor = AppColors.primaryColor; // Default icon color

    return Tooltip(
      // Accessibility feature
      message: tooltip,
      child: Material(
        // Provides ink splash effect and shape clipping
        color: backgroundColor,
        borderRadius: _borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap, // Action to perform on tap
          borderRadius: _borderRadius, // Match shape for splash
          child: Container(
            // Container for size and alignment
            width: 38, height: 38, // Button size
            alignment: Alignment.center,
            // AnimatedSwitcher for smooth icon transition (e.g., heart outline to fill)
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Scale transition for the icon change
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                  child: FadeTransition(
                      opacity: animation, child: child), // Fade effect
                );
              },
              // The Icon itself, using a ValueKey to trigger the animation when isFavorite changes
              child: Icon(
                key: ValueKey<String>(
                    '${isFavorite}_${icon.codePoint}'), // Unique key based on state
                icon,
                color: iconColor ??
                    defaultIconColor, // Use provided color or default
                size: 20, // Icon size
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the widget displayed when an error occurs loading details.
  Widget _buildErrorWidget(
      BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 50), // Error icon
            const Gap(16),
            Text("Oops!", style: theme.textTheme.headlineSmall), // Error title
            const Gap(8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.secondaryColor)), // Error message
            const Gap(16),
            // Retry button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: _borderRadius)),
              onPressed: () => context.read<ServiceProviderDetailBloc>().add(
                  LoadServiceProviderDetails(
                      providerId: providerId)), // Dispatch load event again
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  /// Builds the header image with placeholder and error handling.
  Widget _buildHeaderImage(String? imageUrl, {required double aspectRatio}) {
    // Shimmer placeholder shown while image is loading
    Widget shimmerPlaceholder = AspectRatio(
      aspectRatio: aspectRatio,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      ),
    );

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: AppColors.accentColor
            .withOpacity(0.5), // Background color if image fails
        child: (imageUrl == null || imageUrl.isEmpty)
            // Show icon if no image URL is provided
            ? Center(
                child: Icon(Icons.image_not_supported,
                    size: 60, color: AppColors.secondaryColor.withOpacity(0.5)))
            // Use FadeInImage for smooth image loading
            : FadeInImage.memoryNetwork(
                placeholder:
                    transparentImageData, // Use transparent placeholder bytes
                image: imageUrl,
                fit: BoxFit.cover, // Cover the aspect ratio area
                fadeInDuration: const Duration(milliseconds: 300),
                // Show shimmer placeholder while loading or on error during placeholder load
                placeholderErrorBuilder: (context, error, stackTrace) =>
                    shimmerPlaceholder,
                // Show broken image icon if the main image fails to load
                imageErrorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image,
                        size: 60,
                        color: AppColors.secondaryColor.withOpacity(0.5))),
              ),
      ),
    );
  }

  /// Builds a simple rectangular shimmer placeholder.
  Widget _buildShimmerPlaceholder({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width ?? double.infinity, // Use provided width or expand
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _borderRadius,
        ),
      ),
    );
  }
} // End of ServiceProviderDetailScreen
