import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

// Core utilities and constants
import 'package:shamil_mobile_app/core/constants/icon_constants.dart';
import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // For transparentImageData
import 'package:shamil_mobile_app/core/utils/colors.dart';

// Models
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Blocs
import 'package:shamil_mobile_app/feature/details/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart'; // Import SubscriptionBloc
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart'; // Import ReservationBloc

// Widgets
import 'package:shamil_mobile_app/feature/details/widgets/animated_swipe_up_bar.dart';
import 'package:shamil_mobile_app/feature/details/widgets/options_bottom_sheet.dart'
    as options_sheet; // Use alias

class ServiceProviderDetailScreen extends StatelessWidget {
  final String providerId;
  final String? initialImageUrl;
  final ServiceProviderDisplayModel? initialProviderData;

  const ServiceProviderDetailScreen({
    super.key,
    required this.providerId,
    this.initialImageUrl,
    this.initialProviderData,
  });

  // Consistent styling elements
  static final BorderRadius _borderRadius = BorderRadius.circular(12.0);
  static const EdgeInsets _imagePadding =
      EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0);
  static const EdgeInsets _contentPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const double _imageAspectRatio = 1.0;

  // --- Method to show the bottom sheet (UPDATED with MultiBlocProvider & Bloc constructor args) ---
  void _showOptionsBottomSheet(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    bool isHybrid = provider.pricingModel == PricingModel.hybrid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Wrap with MultiBlocProvider to scope SubscriptionBloc and ReservationBloc
        return MultiBlocProvider(
          providers: [
            BlocProvider<SubscriptionBloc>(
              create: (context) => SubscriptionBloc(),
              // TODO: Inject dependencies like PaymentService if needed
            ),
            BlocProvider<ReservationBloc>(
              // *** FIXED: Pass the required 'provider' object ***
              create: (context) => ReservationBloc(provider: provider),
            ),
          ],
          // Use a Builder to get context below providers
          child: Builder(builder: (blocContext) {
            Widget sheetWidget = DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
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
                  // OptionsBottomSheetContent now has access to the Blocs via blocContext
                  child: options_sheet.OptionsBottomSheetContent(
                    provider: provider,
                    scrollController: scrollController,
                  ),
                );
              },
            );

            // Conditionally wrap with DefaultTabController if needed
            if (isHybrid) {
              return DefaultTabController(
                length: 2,
                child: sheetWidget,
              );
            } else {
              return sheetWidget;
            }
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Provide the ServiceProviderDetailBloc at this level
    return BlocProvider(
      create: (context) => ServiceProviderDetailBloc()
        ..add(LoadServiceProviderDetails(providerId: providerId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // --- Main Content Area (Listens to ServiceProviderDetailBloc State) ---
            BlocConsumer<ServiceProviderDetailBloc, ServiceProviderDetailState>(
              listener: (context, state) {
                // Optional: Handle side effects like showing snackbars for favorite toggle errors
              },
              builder: (context, state) {
                ServiceProviderModel? detailedProvider;
                bool isFullyLoaded = false;
                bool isFavorite = false;

                // Determine current data based on Bloc state or initial data
                if (state is ServiceProviderDetailLoaded) {
                  detailedProvider = state.provider;
                  isFullyLoaded = true;
                  isFavorite = state.isFavorite;
                } else if (initialProviderData != null) {
                  isFavorite = initialProviderData!.isFavorite;
                }

                // Extract data safely
                final providerName = detailedProvider?.businessName ??
                    initialProviderData?.businessName ??
                    'Loading...';
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
                final providerGovernorate = detailedProvider?.governorate;
                final providerDescription =
                    detailedProvider?.businessDescription;
                final providerAmenities = detailedProvider?.amenities;

                // Show Loading Shimmer
                if (!isFullyLoaded &&
                    initialProviderData == null &&
                    (state is ServiceProviderDetailLoading ||
                        state is ServiceProviderDetailInitial)) {
                  return _buildLoadingShimmer(context, theme, initialImageUrl);
                }
                // Show Error Widget
                else if (state is ServiceProviderDetailError) {
                  return _buildErrorWidget(context, theme, state.message);
                }
                // Show Loaded Content
                else {
                  return _buildStackLayoutContent(
                    context,
                    theme,
                    isFullyLoaded: isFullyLoaded,
                    isFavorite: isFavorite,
                    providerId: providerId,
                    heroTag: 'providerImage_$providerId',
                    providerName: providerName,
                    providerImageUrl: providerImageUrl,
                    providerLogoUrl: providerLogoUrl,
                    providerRating: providerRating,
                    providerRatingCount: providerRatingCount,
                    providerCity: providerCity,
                    providerGovernorate: providerGovernorate,
                    providerDescription: providerDescription,
                    providerAmenities: providerAmenities,
                    detailedProviderData: detailedProvider,
                  );
                }
              },
            ),

            // --- Animated Swipe Bar (Listens to ServiceProviderDetailBloc State) ---
            BlocBuilder<ServiceProviderDetailBloc, ServiceProviderDetailState>(
              builder: (context, state) {
                // Show swipe bar only when details are fully loaded
                if (state is ServiceProviderDetailLoaded) {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom),
                      child: AnimatedSwipeUpBar(
                        title: "View Options & Book",
                        onTap: () {
                          // Call helper method to show the bottom sheet
                          _showOptionsBottomSheet(
                              context, theme, state.provider);
                        },
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // Hide if not loaded
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Loading Shimmer Layout ---
  Widget _buildLoadingShimmer(
      BuildContext context, ThemeData theme, String? imageUrlForHero) {
    // (Implementation remains the same)
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageWidth =
        screenWidth - _imagePadding.left - _imagePadding.right;
    final double imageHeight = imageWidth / _imageAspectRatio;
    final shimmerBaseColor = AppColors.accentColor.withOpacity(0.4);
    final shimmerHighlightColor = AppColors.accentColor.withOpacity(0.1);
    final shimmerContentColor = AppColors.white;
    Widget shimmered(Widget child) => Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: child,
        );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top) +
              _imagePadding,
          child: Hero(
            tag: 'providerImage_$providerId',
            child: shimmered(
              ClipRRect(
                borderRadius: _borderRadius,
                child: Container(
                  width: imageWidth,
                  height: imageHeight,
                  color: shimmerContentColor,
                  child: imageUrlForHero != null
                      ? Image.network(imageUrlForHero, fit: BoxFit.cover)
                      : null,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: _contentPadding + const EdgeInsets.only(top: 24),
          child: shimmered(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

  // --- Stack Layout Content ---
  Widget _buildStackLayoutContent(
    BuildContext context,
    ThemeData theme, {
    required bool isFullyLoaded,
    required bool isFavorite,
    required String providerId,
    required String heroTag,
    required String providerName,
    required String? providerImageUrl,
    required String? providerLogoUrl,
    required double providerRating,
    required int providerRatingCount,
    required String providerCity,
    required String? providerGovernorate,
    required String? providerDescription,
    required List<String>? providerAmenities,
    required ServiceProviderModel? detailedProviderData,
  }) {
    // (Implementation remains the same)
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageWidth =
        screenWidth - _imagePadding.left - _imagePadding.right;
    final double imageHeight = imageWidth / _imageAspectRatio;
    final double topSafeArea = MediaQuery.of(context).padding.top;
    final double contentStartY =
        topSafeArea + imageHeight + _imagePadding.top + _imagePadding.bottom;
    Widget titleRowWidget = _buildTitleRowWidget(theme, providerName,
        providerRating, providerRatingCount, providerCity, providerGovernorate);

    return Stack(
      children: [
        Positioned.fill(
          top: contentStartY,
          child: Scrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                  left: _contentPadding.left,
                  right: _contentPadding.right,
                  bottom: 80 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(24),
                  titleRowWidget,
                  const Gap(16),
                  const Divider(color: AppColors.accentColor),
                  const Gap(16),
                  _buildSectionTitle(theme, "Description"),
                  const Gap(8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isFullyLoaded
                        ? _buildDescription(theme, providerDescription ?? '')
                        : Container(
                            key: const ValueKey('desc_shimmer'),
                            child: _buildShimmerPlaceholder(
                                height: 60, width: double.infinity)),
                  ),
                  const Gap(24),
                  _buildSectionTitle(theme, "Facilities"),
                  const Gap(16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isFullyLoaded
                        ? _buildFacilities(theme, providerAmenities ?? [])
                        : Container(
                            key: const ValueKey('fac_shimmer'),
                            child: _buildShimmerPlaceholder(
                                height: 75, width: double.infinity)),
                  ),
                  const Gap(24),
                  _buildSectionTitle(theme, "Plans & Services"),
                  const Gap(8),
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
                  _buildSectionTitle(theme, "Reviews ($providerRatingCount)"),
                  const Gap(8),
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
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: topSafeArea,
          left: 0,
          right: 0,
          child: Padding(
            padding: _imagePadding,
            child: Hero(
              tag: heroTag,
              placeholderBuilder: (context, heroSize, child) {
                return SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Shimmer.fromColors(
                    baseColor: AppColors.accentColor.withOpacity(0.4),
                    highlightColor: AppColors.accentColor.withOpacity(0.1),
                    child: ClipRRect(
                        borderRadius: _borderRadius,
                        child: Container(color: AppColors.white)),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: _borderRadius,
                child: _buildHeaderImage(providerImageUrl,
                    aspectRatio: _imageAspectRatio),
              ),
            ),
          ),
        ),
        if (providerLogoUrl != null && providerLogoUrl.isNotEmpty)
          Positioned(
            top: topSafeArea + _imagePadding.top + imageHeight - 40 - 8,
            left: _imagePadding.left + 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.85),
                borderRadius: _borderRadius,
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 3,
                      spreadRadius: 1)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: providerLogoUrl,
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                  placeholder: (context, url) =>
                      const SizedBox(width: 40, height: 40),
                ),
              ),
            ),
          ),
        Positioned(
          top: topSafeArea + _imagePadding.top + 8,
          left: _imagePadding.left + 8,
          child: _buildOverlayButton(
            context: context,
            theme: theme,
            isFavorite: false,
            icon: Icons.arrow_back_ios_new,
            tooltip: 'Back',
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: topSafeArea + _imagePadding.top + imageHeight - 38 - 8,
          right: _imagePadding.right + 8,
          child: _buildOverlayButton(
            context: context,
            theme: theme,
            isFavorite: isFavorite,
            icon: isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            iconColor: isFavorite ? AppColors.redColor : null,
            tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
            onTap: () {
              context.read<ServiceProviderDetailBloc>().add(
                  ToggleFavoriteStatus(
                      providerId: providerId, currentStatus: isFavorite));
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets (Implementations - Keep unchanged) ---
  Widget _buildTitleRowWidget(ThemeData theme, String name, double rating,
      int ratingCount, String city, String? governorate) {
    String locationString =
        "$city${city.isNotEmpty && governorate != null ? ', ' : ''}${governorate ?? ''}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
            ),
            const Gap(12),
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
                if (ratingCount > 0)
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
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.location_solid,
                size: 16, color: AppColors.secondaryColor),
            const Gap(6),
            Expanded(
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
            const Gap(8),
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
              onPressed: () {/* TODO: Implement map opening */},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme, String description) {
    return Text(
      description.isEmpty ? "No description available." : description,
      style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryColor.withOpacity(0.9), height: 1.5),
    );
  }

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
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: amenities.map((amenityName) {
        final IconData icon = getIconForAmenity(amenityName);
        return _buildFacilityIcon(theme, icon, amenityName);
      }).toList(),
    );
  }

  Widget _buildFacilityIcon(ThemeData theme, IconData icon, String label) {
    return SizedBox(
      width: 75,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.7),
              borderRadius: _borderRadius,
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 24),
          ),
          const Gap(6),
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.primaryColor),
    );
  }

  Widget _buildOverlayButton({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
    required bool isFavorite,
  }) {
    final Color backgroundColor = AppColors.white.withOpacity(0.7);
    final Color defaultIconColor = AppColors.primaryColor;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: _borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: _borderRadius,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                key: ValueKey<String>('${isFavorite}_${icon.codePoint}'),
                icon,
                color: iconColor ?? defaultIconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.redColor, size: 50),
            const Gap(16),
            Text("Error", style: theme.textTheme.headlineSmall),
            const Gap(8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryColor)),
            const Gap(16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: _borderRadius)),
              onPressed: () => context
                  .read<ServiceProviderDetailBloc>()
                  .add(LoadServiceProviderDetails(providerId: providerId)),
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String? imageUrl, {required double aspectRatio}) {
    Widget shimmerPlaceholder = AspectRatio(
      aspectRatio: aspectRatio,
      child: Shimmer.fromColors(
        baseColor: AppColors.accentColor.withOpacity(0.4),
        highlightColor: AppColors.accentColor.withOpacity(0.1),
        child: Container(color: AppColors.white),
      ),
    );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: AppColors.accentColor.withOpacity(0.5),
        child: imageUrl == null || imageUrl.isEmpty
            ? Center(
                child: Icon(Icons.image_not_supported,
                    size: 60, color: AppColors.secondaryColor.withOpacity(0.5)))
            : FadeInImage.memoryNetwork(
                placeholder: transparentImageData,
                image: imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholderErrorBuilder: (context, error, stackTrace) =>
                    shimmerPlaceholder,
                imageErrorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image,
                        size: 60,
                        color: AppColors.secondaryColor.withOpacity(0.5))),
              ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _borderRadius,
        ),
      ),
    );
  }
} // End of ServiceProviderDetailScreen
