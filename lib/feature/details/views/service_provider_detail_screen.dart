import 'dart:async'; // For Timer in carousel
import 'dart:typed_data'; // For Uint8List used in transparentImageData
import 'dart:ui' as ui; // For ImageFilter and Image
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'
    as IconConstants;
// Ensure these paths are correct and models are defined as expected
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';

// Core utilities and constants - Ensure these paths are correct
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';

// Models - Ensure these paths are correct
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
// If SubscriptionPlan is a distinct model from PlanModel, ensure it's correctly defined and imported.
// For example: import 'package:shamil_mobile_app/feature/subscription/data/subscription_plan_model.dart';

// Blocs - Ensure these paths are correct
import 'package:shamil_mobile_app/feature/details/views/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
// import 'package:shamil_mobile_app/feature/subscription/repository/subscription_repository.dart'; // If needed by SubscriptionBloc
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/options_configuration_screen.dart';

// Repository - Ensure these paths are correct
import 'package:shamil_mobile_app/feature/reservation/repository/reservation_repository.dart';

// Widgets - Ensure this path is correct
import 'package:shamil_mobile_app/feature/details/widgets/options_bottom_sheet.dart'
    as options_sheet;

import 'package:provider/provider.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';

/// Displays the detailed view of a service provider using a CustomScrollView and SliverAppBar.
class ServiceProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final ServiceProviderDisplayModel?
      initialProviderData; // For initial header display
  final String heroTag;

  const ServiceProviderDetailScreen({
    super.key,
    required this.providerId,
    this.initialProviderData,
    required this.heroTag,
  });

  @override
  State<ServiceProviderDetailScreen> createState() =>
      _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState
    extends State<ServiceProviderDetailScreen> {
  int _carouselCurrentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showFullDescription = false;

  // --- Helper: Launch URL ---
  Future<void> _launchUrlHelper(
      BuildContext context, String? urlString, String actionType) async {
    if (urlString == null || urlString.isEmpty) {
      if (!mounted) return; // Check mounted before showing snackbar
      showGlobalSnackBar(context, '$actionType is not available.',
          isError: true);
      return;
    }

    if (actionType == "Call" && !urlString.startsWith('tel:')) {
      urlString = 'tel:$urlString';
    } else if (actionType == "Email" && !urlString.startsWith('mailto:')) {
      urlString = 'mailto:$urlString';
    } else if (actionType == "Website" &&
        !urlString.startsWith('http://') &&
        !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (!mounted) return;
      showGlobalSnackBar(context, 'Invalid $actionType link.', isError: true);
      return;
    }
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return; // Check after await

      if (!canLaunch) {
        showGlobalSnackBar(
            context, 'Could not launch $actionType: No app found to handle it.',
            isError: true);
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Error launching $actionType URL ($uri): $e");
      if (!mounted) return; // Check after await
      showGlobalSnackBar(context, 'Error opening $actionType link.',
          isError: true);
    }
  }

  // --- Helper: Show Booking/Options Sheet ---
  void _showBookingOptionsSheet(
      BuildContext parentContext, ServiceProviderModel provider) {
    final theme = Theme.of(parentContext);
    if (!provider.canBookOrSubscribeOnline) {
      showGlobalSnackBar(
          parentContext, "Online booking/subscription not available.",
          isError: false);
      return;
    }

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetBuilderContext) {
        return MultiBlocProvider(
          providers: [
            if (provider.hasSubscriptionsEnabled)
              BlocProvider<SubscriptionBloc>(
                  create: (blocContext) => SubscriptionBloc(
                      // IMPORTANT: Provide the repository if SubscriptionBloc needs one.
                      // Example: repository: blocContext.read<SubscriptionRepository>(),
                      )
                    ..add(ResetSubscriptionFlow())),
            if (provider.hasReservationsEnabled)
              BlocProvider<ReservationBloc>(
                  create: (blocContext) => ReservationBloc(
                      provider: provider,
                      reservationRepository:
                          blocContext.read<ReservationRepository>())
                    ..add(ResetReservationFlow(provider: provider))),
            BlocProvider.value(value: parentContext.read<SocialBloc>()),
          ],
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (BuildContext scrollableSheetContext,
                ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(scrollableSheetContext).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20.0)),
                  boxShadow: kElevationToShadow[
                      4], // Ensure kElevationToShadow is defined
                ),
                child: options_sheet.OptionsBottomSheetContent(
                  provider: provider,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Helper: Navigate to Options Configuration ---
  void _navigateToOptionsConfiguration(BuildContext context,
      {ServiceProviderModel? provider,
      SubscriptionPlan? plan,
      BookableService? service}) {
    // Your app's BookableService model

    final currentState = context.read<ServiceProviderDetailBloc>().state;
    ServiceProviderModel? currentProvider = provider;
    if (currentProvider == null &&
        currentState is ServiceProviderDetailLoaded) {
      currentProvider = currentState.provider;
    }

    if (currentProvider == null) {
      if (!mounted) return;
      showGlobalSnackBar(context, "Provider details not fully loaded yet.",
          isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OptionsConfigurationScreen(
          providerId: currentProvider!.id,
          // The following casts are workarounds for type mismatches.
          // See "Important Recommendations" after the code block.
          plan: plan as PlanModel?,
          service: service as ServiceModel?,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Forward the existing global FavoritesBloc so it is accessible in this subtree
        BlocProvider<FavoritesBloc>.value(
          value: BlocProvider.of<FavoritesBloc>(context),
        ),
        Provider<ServiceProviderDetailRepository>(
          create: (_) => FirebaseServiceProviderDetailRepository(),
        ),
        BlocProvider<ServiceProviderDetailBloc>(
          create: (context) => ServiceProviderDetailBloc(
            detailRepository: context.read<ServiceProviderDetailRepository>(),
          )..add(LoadServiceProviderDetails(providerId: widget.providerId)),
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        // Add haptic feedback on page load for premium feel
        body: Builder(builder: (context) {
          Future.delayed(const Duration(milliseconds: 200), () {
            // Light impact feedback when screen loads
            HapticFeedback.lightImpact();
          });

          return BlocConsumer<ServiceProviderDetailBloc,
              ServiceProviderDetailState>(
            listener: (context, state) {
              if (state is ServiceProviderDetailError &&
                  widget.initialProviderData != null) {
                showGlobalSnackBar(context, "Error: ${state.message}",
                    isError: true);
              }
            },
            builder: (context, state) {
              ServiceProviderModel? detailedProvider;
              ServiceProviderDisplayModel? displayData =
                  widget.initialProviderData;
              bool isLoading = true;
              bool isFavorite = widget.initialProviderData?.isFavorite ?? false;
              List<String> headerImages = [];

              // Determine favorite status from global FavoritesBloc if loaded
              final favState = BlocProvider.of<FavoritesBloc>(context).state;
              if (favState is FavoritesLoaded) {
                isFavorite =
                    favState.favorites.any((p) => p.id == widget.providerId);
              }

              if (state is ServiceProviderDetailLoading) {
                isLoading = true;
                if (displayData?.imageUrl != null &&
                    displayData!.imageUrl!.isNotEmpty) {
                  headerImages.add(displayData.imageUrl!);
                }
              } else if (state is ServiceProviderDetailLoaded) {
                detailedProvider = state.provider;
                displayData = ServiceProviderDisplayModel(
                  /* ... mapping from detailedProvider ... */
                  id: detailedProvider.id,
                  businessName: detailedProvider.businessName,
                  imageUrl: detailedProvider.mainImageUrl,
                  businessLogoUrl: detailedProvider.logoUrl,
                  businessCategory: detailedProvider.category,
                  subCategory: detailedProvider.subCategory,
                  averageRating: detailedProvider.rating ?? 0.0,
                  ratingCount: detailedProvider.ratingCount ?? 0,
                  city: detailedProvider.city ?? '',
                  isFavorite: state.isFavorite,
                  shortDescription: detailedProvider.businessDescription
                      .substring(
                          0,
                          (detailedProvider.businessDescription.length > 100
                              ? 100
                              : detailedProvider.businessDescription.length)),
                  isFeatured: detailedProvider.isFeatured,
                  isActive: detailedProvider.isActive,
                  isApproved: detailedProvider.isApproved,
                );
                isFavorite = state.isFavorite;
                isLoading = false;

                if (detailedProvider.mainImageUrl != null &&
                    detailedProvider.mainImageUrl!.isNotEmpty) {
                  headerImages.add(detailedProvider.mainImageUrl!);
                }
                if (detailedProvider.galleryImageUrls != null) {
                  headerImages.addAll(detailedProvider.galleryImageUrls!
                      .where((url) => url.isNotEmpty));
                }
                headerImages =
                    headerImages.toSet().toList(); // Remove duplicates
                if (headerImages.isEmpty) {
                  // Use a placeholder or logo if no images are available and initialProviderData has none
                  if (displayData?.imageUrl != null &&
                      displayData!.imageUrl!.isNotEmpty) {
                    headerImages.add(displayData.imageUrl!);
                  } else if (displayData?.businessLogoUrl != null &&
                      displayData!.businessLogoUrl!.isNotEmpty) {
                    headerImages.add(displayData.businessLogoUrl!);
                  } else {
                    headerImages.add(''); // True placeholder for empty image
                  }
                }
              } else if (state is ServiceProviderDetailError) {
                isLoading = false;
                if (displayData?.imageUrl != null &&
                    displayData!.imageUrl!.isNotEmpty) {
                  headerImages.add(displayData.imageUrl!);
                } else if (headerImages.isEmpty) {
                  headerImages.add('');
                }
              } else if (state is ServiceProviderDetailInitial) {
                isLoading = true;
                if (displayData?.imageUrl != null &&
                    displayData!.imageUrl!.isNotEmpty) {
                  headerImages.add(displayData.imageUrl!);
                } else if (headerImages.isEmpty) {
                  headerImages.add('');
                }
              }

              if (displayData == null && isLoading) {
                return _buildLoadingShimmer(
                    context, Theme.of(context), widget.heroTag);
              }
              if (displayData == null && state is ServiceProviderDetailError) {
                return _buildErrorWidget(context, Theme.of(context),
                    state.message, widget.providerId);
              }

              if (displayData != null) {
                return Stack(
                  children: [
                    // Main content
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: <Widget>[
                        _SliverProviderHeaderDelegate.buildHeader(
                          context: context,
                          providerDisplayData: displayData,
                          theme: Theme.of(context),
                          heroTag: widget.heroTag,
                          isFavorite: isFavorite,
                          headerImages: headerImages,
                          carouselIndex: _carouselCurrentIndex,
                          onCarouselPageChanged: (index, reason) {
                            if (mounted) {
                              setState(() {
                                _carouselCurrentIndex = index;
                              });
                            }
                          },
                          onFavoriteToggle: () {
                            final favoritesBloc =
                                BlocProvider.of<FavoritesBloc>(context);
                            if (isFavorite) {
                              favoritesBloc
                                  .add(RemoveFromFavorites(widget.providerId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from favorites'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if (displayData != null) {
                              favoritesBloc.add(AddToFavorites(displayData!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to favorites'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        if (isLoading && detailedProvider == null)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (detailedProvider != null)
                          _buildLoadedContentSlivers(context, Theme.of(context),
                              detailedProvider, BorderRadius.circular(16.0))
                        else if (state is ServiceProviderDetailError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorWidget(context, Theme.of(context),
                                state.message, widget.providerId),
                          )
                        else
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: Text("Loading details...")),
                          ),
                        const SliverGap(30.0),
                      ],
                    ),
                  ],
                );
              }
              return const Center(child: Text("An unexpected error occurred."));
            },
          );
        }),
      ),
    );
  }

  Widget _buildLoadedContentSlivers(BuildContext passedContext, ThemeData theme,
      ServiceProviderModel provider, BorderRadius cardRadius) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRatingLocation(theme, provider),
              const Gap(24),
              _buildActionButtons(passedContext, theme, provider),
              const Gap(20),
              const Divider(),
              const Gap(20),
              _buildSectionTitle(theme, "About"),
              const Gap(10),
              Text(
                  provider.businessDescription.isEmpty
                      ? "No description provided."
                      : provider.businessDescription,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
              const Gap(12),
              if (provider.yearsInBusiness != null &&
                  provider.yearsInBusiness! > 0)
                _buildInfoRow(
                    passedContext,
                    theme,
                    Icons.history_toggle_off_rounded,
                    "In Business Since",
                    "${DateTime.now().year - provider.yearsInBusiness!} (${provider.yearsInBusiness} Years)"),
              const Gap(12),
              if (provider.averageResponseTime != null)
                _buildInfoRow(passedContext, theme, Icons.access_time_rounded,
                    "Response Time", provider.averageResponseTime!),
              const Gap(20),
              if (provider.amenities.isNotEmpty) ...[
                const Divider(),
                const Gap(20),
                _buildSectionTitle(theme, "Facilities"),
                const Gap(16),
                _buildFacilities(theme, provider.amenities),
                const Gap(20),
              ],
              if (provider.bookableServices.isNotEmpty &&
                  provider.pricingModel != PricingModel.subscription) ...[
                const Divider(),
                const Gap(20),
                _buildSectionTitle(theme, "Bookable Services"),
                const Gap(12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.bookableServices.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, indent: 0, endIndent: 0),
                  itemBuilder: (itemCtx, index) {
                    final service = provider.bookableServices[index];
                    return _buildServiceCard(
                        itemCtx, theme, service, cardRadius, provider);
                  },
                ),
                const Gap(20),
              ],
              if (provider.subscriptionPlans.isNotEmpty &&
                  provider.pricingModel != PricingModel.reservation) ...[
                const Divider(),
                const Gap(20),
                _buildSectionTitle(theme, "Subscription Plans"),
                const Gap(12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.subscriptionPlans.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, indent: 0, endIndent: 0),
                  itemBuilder: (itemCtx, index) {
                    final plan = provider.subscriptionPlans[index];
                    return _buildSubscriptionPlanCard(
                        itemCtx, theme, plan, cardRadius, provider);
                  },
                ),
                const Gap(20),
              ],
              const Divider(),
              const Gap(20),
              _buildSectionTitle(theme, "Location"),
              const Gap(12),
              _buildInfoRow(passedContext, theme, Icons.location_pin, "Address",
                  "${provider.street ?? ''}${provider.street != null ? ', ' : ''}${provider.city ?? ''}${provider.city != null ? ', ' : ''}${provider.governorate ?? ''}"),
              const Gap(12),
              _buildMapPlaceholder(passedContext, theme, provider),
              const Gap(20),
              if (provider.openingHours.isNotEmpty) ...[
                const Divider(),
                const Gap(20),
                _buildSectionTitle(theme, "Operating Hours"),
                const Gap(12),
                _buildOpeningHours(passedContext, theme, provider.openingHours),
                const Gap(20),
              ],
              const Divider(),
              const Gap(20),
              _buildSectionTitle(theme, "Contact & Information"),
              const Gap(12),
              if (provider.primaryPhoneNumber != null)
                _buildInfoRow(passedContext, theme, Icons.phone_outlined,
                    "Phone", provider.primaryPhoneNumber!),
              if (provider.primaryEmail != null)
                _buildInfoRow(passedContext, theme, Icons.email_outlined,
                    "Email", provider.primaryEmail!),
              if (provider.website != null)
                _buildInfoRow(passedContext, theme, Icons.language_outlined,
                    "Website", provider.website!),
              if (provider.paymentMethodsAccepted != null &&
                  provider.paymentMethodsAccepted!.isNotEmpty)
                _buildInfoRow(
                    passedContext,
                    theme,
                    Icons.payment_rounded,
                    "Payment Methods",
                    provider.paymentMethodsAccepted!.join(', ')),
              const Gap(24),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTitleRatingLocation(
      ThemeData theme, ServiceProviderModel provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered logo
          if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: provider.logoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(Icons.business_outlined,
                        color: Colors.grey[400], size: 40),
                  ),
                ),
              ),
            ),

          // Business name
          const SizedBox(height: 16),
          Text(
            provider.businessName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          // Category tag
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              provider.subCategory != null && provider.subCategory!.isNotEmpty
                  ? "${provider.category} • ${provider.subCategory}"
                  : provider.category,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Rating stars
          const SizedBox(height: 16),
          _buildRatingStars(theme, provider),

          // Location
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                "${provider.city ?? ''}${provider.governorate != null && provider.city != null ? ', ' : ''}${provider.governorate ?? ''}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(ThemeData theme, ServiceProviderModel provider) {
    // Generate star display based on rating
    final List<Widget> stars = List.generate(5, (index) {
      if (index < provider.rating.floor()) {
        return Icon(Icons.star, color: Colors.amber, size: 22);
      } else if (index < provider.rating.ceil() && provider.rating % 1 > 0) {
        return Icon(Icons.star_half, color: Colors.amber, size: 22);
      } else {
        return Icon(Icons.star_border, color: Colors.amber, size: 22);
      }
    });

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stars,
        ),
        const SizedBox(height: 4),
        Text(
          "${provider.rating.toStringAsFixed(1)} (${provider.ratingCount} ${provider.ratingCount == 1 ? 'review' : 'reviews'})",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    bool hasPhone = provider.primaryPhoneNumber != null &&
        provider.primaryPhoneNumber!.isNotEmpty;
    bool hasLocation = provider.location != null;
    bool hasWebsite = provider.website != null && provider.website!.isNotEmpty;

    if (!hasPhone && !hasLocation && !hasWebsite) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "Quick Actions",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (hasPhone)
                  _buildActionButton(
                    context,
                    theme,
                    Icons.call_outlined,
                    "Call",
                    () => _launchUrlHelper(
                        context, provider.primaryPhoneNumber, "Call"),
                  ),
                if (hasLocation)
                  _buildActionButton(
                    context,
                    theme,
                    Icons.directions_outlined,
                    "Directions",
                    () {
                      if (provider.location != null) {
                        final lat = provider.location!.latitude;
                        final lon = provider.location!.longitude;
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                        _launchUrlHelper(context, url, "Directions");
                      }
                    },
                  ),
                if (hasWebsite)
                  _buildActionButton(
                    context,
                    theme,
                    Icons.language_outlined,
                    "Website",
                    () =>
                        _launchUrlHelper(context, provider.website, "Website"),
                  ),
                if (provider.primaryEmail != null)
                  _buildActionButton(
                    context,
                    theme,
                    Icons.email_outlined,
                    "Email",
                    () => _launchUrlHelper(
                        context, provider.primaryEmail, "Email"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ThemeData theme, IconData icon,
      String label, String value) {
    bool isLink = label == "Phone" || label == "Email" || label == "Website";
    String urlToLaunch =
        value; // Prepare the URL string properly for _launchUrlHelper

    if (label == "Phone" && !value.startsWith('tel:')) {
      urlToLaunch = 'tel:$value';
    } else if (label == "Email" && !value.startsWith('mailto:')) {
      urlToLaunch = 'mailto:$value';
    } else if (label == "Website" &&
        !value.startsWith('http://') &&
        !value.startsWith('https://')) {
      // It's good practice to default to https if no scheme is present for websites
      urlToLaunch = 'https://$value';
    }
    // For other types of labels, urlToLaunch remains the original value,
    // and _launchUrlHelper will handle it (or fail gracefully if it's not a launchable URL type).

    return InkWell(
      onTap:
          isLink ? () => _launchUrlHelper(context, urlToLaunch, label) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  const Gap(3),
                  Text(value, // Display the original value
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: isLink ? theme.colorScheme.primary : null,
                          fontWeight: isLink ? FontWeight.w500 : null)),
                ],
              ),
            ),
            if (isLink) const Gap(8),
            if (isLink)
              Icon(Icons.open_in_new_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilities(ThemeData theme, List<String> amenities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        children: amenities.map((amenityName) {
          final IconData icon = IconConstants.getIconForAmenity(amenityName);
          return Container(
            width: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentColor.withOpacity(0.1),
                        AppColors.accentColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 28),
                ),
                const Gap(8),
                Text(
                  amenityName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpeningHours(BuildContext context, ThemeData theme,
      Map<String, OpeningHoursDay> hoursMap) {
    final today = DateFormat('EEEE', Localizations.localeOf(context).toString())
        .format(DateTime.now())
        .toLowerCase(); // Use locale-aware DateFormat
    final daysOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Column(
      children: daysOrder.map((day) {
        final hours = hoursMap[day];
        final bool isToday = day == today;
        // Consider localizing day names if app supports multiple languages
        final String displayDay = day[0].toUpperCase() + day.substring(1);
        String displayHours;
        if (hours == null ||
            !hours.isOpen ||
            hours.startTime == null ||
            hours.endTime == null) {
          displayHours = "Closed";
        } else {
          final localizations = MaterialLocalizations.of(context);
          final startFormatted = localizations.formatTimeOfDay(hours.startTime!,
              alwaysUse24HourFormat: MediaQuery.of(context)
                  .alwaysUse24HourFormat); // Respect user's 24hr preference
          final endFormatted = localizations.formatTimeOfDay(hours.endTime!,
              alwaysUse24HourFormat:
                  MediaQuery.of(context).alwaysUse24HourFormat);
          displayHours = "$startFormatted - $endFormatted";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDay,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? theme.colorScheme.primary : null,
                ),
              ),
              Text(
                displayHours,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: (hours == null || !hours.isOpen)
                      ? Colors.grey.shade600
                      : (isToday ? theme.colorScheme.primary : null),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Contextual icon
          Icon(
            _getSectionIcon(title),
            size: 18,
            color: AppColors.secondaryText.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title.toLowerCase()) {
      case "about":
        return Icons.info_outline_rounded;
      case "facilities":
        return Icons.hotel_class_outlined;
      case "bookable services":
        return Icons.event_available_outlined;
      case "subscription plans":
        return Icons.card_membership_outlined;
      case "location":
        return Icons.place_outlined;
      case "operating hours":
        return Icons.access_time_outlined;
      case "contact & information":
        return Icons.contact_phone_outlined;
      default:
        return Icons.arrow_right_alt_rounded;
    }
  }

  Widget _buildSubscriptionPlanCard(
      BuildContext context,
      ThemeData theme,
      SubscriptionPlan plan,
      BorderRadius cardRadius,
      ServiceProviderModel provider) {
    final intervalStr =
        "${plan.intervalCount > 1 ? '${plan.intervalCount} ' : ''}${plan.interval.name}${plan.intervalCount > 1 ? 's' : ''}"; // Ensure plan.interval.name is correct
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _navigateToOptionsConfiguration(context,
              plan: plan, provider: provider),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Gap(8),
                          Text(plan.description,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const Gap(16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor.withOpacity(0.9),
                                AppColors.primaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "EGP ${plan.price.toStringAsFixed(0)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "/ $intervalStr",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (plan.features.isNotEmpty) ...[
                  const Gap(16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: plan.features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentColor.withOpacity(0.1),
                              AppColors.accentColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          feature,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context,
      ThemeData theme,
      BookableService service,
      BorderRadius cardRadius,
      ServiceProviderModel provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToOptionsConfiguration(context,
              service: service, provider: provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service header with name and service icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service icon with clean style
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getServiceIcon(service.name),
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          if (service.durationMinutes != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${service.durationMinutes} min",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Price tag
                    if (service.price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "EGP ${service.price!.toStringAsFixed(0)}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                // Service description
                const SizedBox(height: 12),
                Text(
                  service.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Book now button
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _navigateToOptionsConfiguration(context,
                        service: service, provider: provider),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to get contextual icons for services based on name
  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();

    if (name.contains('consult') ||
        name.contains('advice') ||
        name.contains('session')) {
      return Icons.people_outline_rounded;
    } else if (name.contains('therapy') ||
        name.contains('massage') ||
        name.contains('spa')) {
      return Icons.spa_rounded;
    } else if (name.contains('class') ||
        name.contains('lesson') ||
        name.contains('course')) {
      return Icons.school_rounded;
    } else if (name.contains('cut') ||
        name.contains('hair') ||
        name.contains('style')) {
      return Icons.content_cut_rounded;
    } else if (name.contains('treatment') || name.contains('procedure')) {
      return Icons.healing_rounded;
    } else if (name.contains('test') ||
        name.contains('check') ||
        name.contains('exam')) {
      return Icons.assignment_rounded;
    } else {
      return Icons.event_available_rounded; // Default
    }
  }

  Widget _buildMapPlaceholder(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors
                .grey.shade200, // Consider theme.colorScheme.surfaceVariant
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(Icons.map_outlined,
                size: 50,
                color: Colors.grey
                    .shade400), // Consider theme.colorScheme.onSurfaceVariant
          ),
        ),
        const Gap(8),
        TextButton.icon(
          icon: Icon(Icons.open_in_new_rounded,
              size: 16, color: Theme.of(context).colorScheme.primary),
          label: Text("Open in Maps",
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          onPressed: provider.location != null
              ? () {
                  if (provider.location != null) {
                    final lat = provider.location!.latitude;
                    final lon = provider.location!.longitude;
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                    _launchUrlHelper(context, url, "Map");
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(
      BuildContext context, ThemeData theme, String heroTag) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust shimmer aspect ratio to match _SliverProviderHeaderDelegate maxExtent
    final double headerImageHeight =
        screenWidth / (16 / 9); // Assuming 16:9, match with delegate
    final shimmerBaseColor = Colors.grey.shade300;
    final shimmerHighlightColor = Colors.grey.shade100;
    final shimmerContentColor = Colors.white;
    final radius = BorderRadius.circular(12.0);

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: headerImageHeight +
                MediaQuery.of(context)
                    .padding
                    .top, // Match delegate's maxExtent
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: shimmerBaseColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag, // Ensure heroTag is consistent
                child: Container(color: shimmerContentColor),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: screenWidth * 0.8,
                        height: 28,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(10),
                    Container(
                        width: screenWidth * 0.6,
                        height: 18,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(10),
                    Container(
                        width: screenWidth * 0.7,
                        height: 18,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                    color: shimmerContentColor,
                                    borderRadius: radius))),
                        const Gap(12),
                        Expanded(
                            child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                    color: shimmerContentColor,
                                    borderRadius: radius))),
                      ],
                    ),
                    const Gap(20),
                    const Divider(),
                    const Gap(20),
                    Container(
                        width: 120,
                        height: 22,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(12),
                    Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(20),
                    const Divider(),
                    const Gap(20),
                    Container(
                        width: 120,
                        height: 22,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                    const Gap(12),
                    Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: shimmerContentColor, borderRadius: radius)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, ThemeData theme,
      String message, String currentProviderId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 50),
            const Gap(16),
            Text("Oops!", style: theme.textTheme.headlineSmall),
            const Gap(8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.secondary)),
            const Gap(24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0))),
              onPressed: () => context.read<ServiceProviderDetailBloc>().add(
                  LoadServiceProviderDetails(providerId: currentProviderId)),
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}

class _SliverProviderHeaderDelegate extends SliverPersistentHeaderDelegate {
  final BuildContext
      parentContext; // Context from _ServiceDetailsViewState's build method
  final ServiceProviderDisplayModel providerDisplayData;
  final ThemeData theme;
  final String heroTag;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final List<String> headerImages;
  final int carouselIndex;
  final Function(int index, CarouselPageChangedReason reason)
      onCarouselPageChanged;

  _SliverProviderHeaderDelegate({
    required this.parentContext,
    required this.providerDisplayData,
    required this.theme,
    required this.heroTag,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.headerImages,
    required this.carouselIndex,
    required this.onCarouselPageChanged,
  });

  static Widget buildHeader({
    required BuildContext
        context, // This is _ServiceDetailsViewState's build context
    required ServiceProviderDisplayModel providerDisplayData,
    required ThemeData theme,
    required String heroTag,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
    required List<String> headerImages,
    required int carouselIndex,
    required Function(int index, CarouselPageChangedReason reason)
        onCarouselPageChanged,
  }) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverProviderHeaderDelegate(
        parentContext: context, // Pass the _ServiceDetailsViewState's context
        providerDisplayData: providerDisplayData,
        theme: theme,
        heroTag: heroTag,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        headerImages: headerImages,
        carouselIndex: carouselIndex,
        onCarouselPageChanged: onCarouselPageChanged,
      ),
    );
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double topSafeArea = MediaQuery.of(parentContext).padding.top;
    final double currentExtent = maxExtent - shrinkOffset;
    final double titleOpacity =
        (1.0 - (currentExtent - minExtent) / (maxExtent - minExtent))
            .clamp(0.0, 1.0);

    bool noImagesAvailable = headerImages.isEmpty ||
        (headerImages.length == 1 && headerImages.first.isEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Top bar with back button and actions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: minExtent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(top: topSafeArea),
            color: Colors.white.withOpacity(titleOpacity),
            child: Stack(
              children: [
                // Back button
                Positioned(
                  left: 16,
                  top: 8,
                  child: _buildCleanButton(
                    context: parentContext,
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(parentContext);
                    },
                  ),
                ),
                // Action buttons
                Positioned(
                  right: 16,
                  top: 8,
                  child: Row(
                    children: [
                      // Share button
                      _buildCleanButton(
                        context: parentContext,
                        icon: Icons.share_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Heart button
                      _buildFavoriteButton(
                        context: parentContext,
                        isFavorite: isFavorite,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onFavoriteToggle();
                        },
                      ),
                    ],
                  ),
                ),
                // Title
                Positioned(
                  left: 70,
                  right: 70,
                  top: 13,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: titleOpacity,
                    child: Text(
                      providerDisplayData.businessName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Photo carousel
        Positioned(
          top: minExtent,
          left: 0,
          right: 0,
          height: maxExtent - minExtent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0), // Changed to 8px radius
            child: noImagesAvailable
                ? Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          color: Colors.grey[400], size: 60),
                    ),
                  )
                : CarouselSlider.builder(
                    itemCount: headerImages.length,
                    itemBuilder: (context, index, realIndex) {
                      final imageUrl = headerImages[index];
                      if (imageUrl.isEmpty) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_outlined,
                                color: Colors.grey[400], size: 60),
                          ),
                        );
                      }
                      return Hero(
                        tag: heroTag,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CupertinoActivityIndicator(radius: 15),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.grey[400], size: 60),
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: headerImages.length > 1,
                      autoPlay: headerImages.length > 1,
                      autoPlayInterval: const Duration(seconds: 6),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      onPageChanged: onCarouselPageChanged,
                    ),
                  ),
          ),
        ),
        // Image counter and dots indicator
        if (!noImagesAvailable && headerImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Image counter
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${carouselIndex + 1}/${headerImages.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Dots indicator
                DotsIndicator(
                  dotsCount: headerImages.length,
                  position: carouselIndex
                      .toDouble()
                      .clamp(0.0, (headerImages.length - 1).toDouble()),
                  decorator: DotsDecorator(
                    size: const Size.square(6.0),
                    activeSize: const Size(18.0, 6.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    color: Colors.black.withOpacity(0.2),
                    activeColor: AppColors.primaryColor,
                    spacing: const EdgeInsets.symmetric(horizontal: 3),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // New clean button style without gradients
  Widget _buildCleanButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.primaryText,
            size: 20,
          ),
        ),
      ),
    );
  }

  // New favorite button style
  Widget _buildFavoriteButton({
    required BuildContext context,
    required bool isFavorite,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            child: isFavorite
                ? Icon(
                    Icons.favorite_rounded,
                    key: const ValueKey('fav'),
                    color: Colors.redAccent,
                    size: 20,
                  )
                : Icon(
                    Icons.favorite_border_rounded,
                    key: const ValueKey('unfav'),
                    color: AppColors.primaryText,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent =>
      MediaQuery.of(parentContext).size.width +
      MediaQuery.of(parentContext).padding.top;

  @override
  double get minExtent =>
      kToolbarHeight + MediaQuery.of(parentContext).padding.top;

  @override
  bool shouldRebuild(_SliverProviderHeaderDelegate oldDelegate) {
    return parentContext != oldDelegate.parentContext ||
        providerDisplayData.id != oldDelegate.providerDisplayData.id ||
        providerDisplayData.businessName !=
            oldDelegate.providerDisplayData.businessName ||
        heroTag != oldDelegate.heroTag ||
        isFavorite != oldDelegate.isFavorite ||
        !listEquals(headerImages, oldDelegate.headerImages) ||
        carouselIndex != oldDelegate.carouselIndex;
  }
}

// Helper Extension
extension ServiceProviderModelBooking on ServiceProviderModel {
  bool get canBookOrSubscribeOnline =>
      pricingModel != PricingModel.other &&
      (hasReservationsEnabled || hasSubscriptionsEnabled);
  bool get hasReservationsEnabled =>
      (pricingModel == PricingModel.reservation ||
          pricingModel == PricingModel.hybrid) &&
      supportedReservationTypes.isNotEmpty;
  bool get hasSubscriptionsEnabled =>
      (pricingModel == PricingModel.subscription ||
          pricingModel == PricingModel.hybrid) &&
      subscriptionPlans.isNotEmpty;
  String get getBookingButtonText {
    if (pricingModel == PricingModel.reservation) return "Book / View Options";
    if (pricingModel == PricingModel.subscription)
      return "View Subscription Plans";
    if (pricingModel == PricingModel.hybrid) return "View Booking & Plans";
    return "Contact Provider";
  }
}

// Helper to compare lists, import from flutter/foundation.dart
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
