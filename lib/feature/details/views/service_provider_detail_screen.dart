// lib/feature/details/views/service_provider_detail_screen.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show listEquals; // For listEquals
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'
    as AppIcons;
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/reservation_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';

import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show ReservationType, ReservationTypeExtension;

import 'package:shamil_mobile_app/feature/details/views/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/options_configuration_screen.dart';
import 'package:shamil_mobile_app/feature/details/widgets/options_bottom_sheet.dart'
    as options_sheet;

class ServiceProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final ServiceProviderDisplayModel? initialProviderData;
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
  // bool _showFullDescription = false; // Can be managed by ExpansionTile

  Future<void> _launchUrlHelper(
      BuildContext context, String? urlString, String actionType) async {
    if (urlString == null || urlString.isEmpty) {
      if (!mounted) return;
      showGlobalSnackBar(context, '$actionType is not available.',
          isError: true);
      return;
    }

    String schemeUrl = urlString;
    if (actionType == "Call" && !urlString.startsWith('tel:')) {
      schemeUrl = 'tel:$urlString';
    } else if (actionType == "Email" && !urlString.startsWith('mailto:')) {
      schemeUrl = 'mailto:$urlString';
    } else if ((actionType == "Website" || actionType == "Map") &&
        !urlString.startsWith('http://') &&
        !urlString.startsWith('https://')) {
      schemeUrl = 'https://$urlString';
    }

    final Uri? uri = Uri.tryParse(schemeUrl);
    if (uri == null) {
      if (!mounted) return;
      showGlobalSnackBar(context, 'Invalid $actionType link.', isError: true);
      return;
    }
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;

      if (!canLaunch) {
        showGlobalSnackBar(
            context, 'Could not launch $actionType: No app found to handle it.',
            isError: true);
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      showGlobalSnackBar(context, 'Error opening $actionType link: $e',
          isError: true);
    }
  }

  void _showBookingOptionsSheet(
      BuildContext parentContext, ServiceProviderModel provider) {
    // final theme = Theme.of(parentContext); // Not used directly here now
    if (!provider.canBookOrSubscribeOnline) {
      showGlobalSnackBar(parentContext,
          "Online booking/subscription not available for this provider.",
          isError: false);
      return;
    }

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context:
          parentContext, // Use parentContext which has all the necessary BLoCs
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetBuilderContext) {
        // sheetBuilderContext is new and local
        return MultiBlocProvider(
          // Provide BLoCs needed by OptionsBottomSheetContent
          providers: [
            // FavoritesBloc is already available via parentContext.read or BlocProvider.of
            // SocialBloc is already available via parentContext.read or BlocProvider.of
            if (provider.hasSubscriptionsEnabled)
              BlocProvider<SubscriptionBloc>(
                  create: (_) => SubscriptionBloc(
                      // Assuming SubscriptionRepository and AuthBloc are globally available or passed if needed
                      // authBloc: parentContext.read<AuthBloc>(),
                      // repository: parentContext.read<SubscriptionRepository>(),
                      )
                    ..add(ResetSubscriptionFlow())),
            if (provider.hasReservationsEnabled)
              BlocProvider<ReservationBloc>(
                  create: (_) => ReservationBloc(
                        provider: provider,
                        reservationRepository: parentContext.read<
                            ReservationRepository>(), // Read existing repo
                        // authBloc: parentContext.read<AuthBloc>(),
                      )..add(ResetReservationFlow(provider: provider))),
          ],
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (BuildContext
                    scrollableSheetContext, // Use this distinct context
                ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(scrollableSheetContext).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, -5),
                    )
                  ],
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

  void _navigateToOptionsConfiguration(BuildContext context,
      {BookableService? service,
      SubscriptionPlan? planData,
      required ServiceProviderModel provider}) {
    ServiceModel? serviceModelForConfig;
    PlanModel? planModelForConfig;

    if (service != null) {
      serviceModelForConfig =
          _convertBookableServiceToServiceModel(service, provider.id, provider);
    } else if (planData != null) {
      planModelForConfig =
          _convertSubscriptionPlanToPlanModel(planData, provider.id, provider);
    } else {
      showGlobalSnackBar(context, "No item selected for configuration.",
          isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
                providers: [
                  // Forward BLoCs that OptionsConfigurationScreen might need
                  // OptionsConfigurationBloc is created internally by OptionsConfigurationScreen
                  BlocProvider.value(
                      value: BlocProvider.of<SocialBloc>(context)),
                  BlocProvider.value(
                      value: BlocProvider.of<AuthBloc>(
                          context)), // If AuthBloc is needed
                ],
                child: OptionsConfigurationScreen(
                  providerId: provider.id,
                  plan: planModelForConfig,
                  service: serviceModelForConfig,
                ),
              )),
    );
  }

  ServiceModel _convertBookableServiceToServiceModel(
      BookableService bookableService,
      String providerId,
      ServiceProviderModel detailedProvider) {
    Map<String, dynamic> optionsDef =
        Map<String, dynamic>.from(bookableService.configData ?? {});
    final String serviceTypeKey =
        bookableService.type.typeString; // Ensure typeString is available
    final generalTypeConfig =
        detailedProvider.reservationTypeConfigs?[serviceTypeKey];

    if (generalTypeConfig is Map) {
      generalTypeConfig.forEach((key, value) {
        optionsDef.putIfAbsent(key, () => value);
      });
    }

    switch (bookableService.type) {
      case ReservationType.timeBased:
      case ReservationType.seatBased:
      case ReservationType.recurring:
      case ReservationType.group:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('allowTimeSelection', () => true);
        optionsDef.putIfAbsent('timeSelectionType',
            () => optionsDef['timeSelectionType'] ?? 'slots');
        break;
      case ReservationType.serviceBased:
        optionsDef.putIfAbsent('allowDateSelection',
            () => optionsDef['allowDateSelection'] ?? false);
        optionsDef.putIfAbsent('allowTimeSelection',
            () => optionsDef['allowTimeSelection'] ?? false);
        break;
      case ReservationType.accessBased:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('requiresAccessPassSelection', () => true);
        if (detailedProvider.accessOptions != null &&
            detailedProvider.accessOptions!.isNotEmpty) {
          optionsDef.putIfAbsent(
              'definedAccessPasses',
              () => detailedProvider.accessOptions!
                  .map((e) => e.toMap())
                  .toList());
        }
        break;
      case ReservationType.sequenceBased:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('allowTimeSelection', () => true);
        optionsDef.putIfAbsent('timeSelectionType', () => 'preference');
        break;
      default:
        break;
    }

    bool defaultAllowAttendeeSelection =
        bookableService.type == ReservationType.group ||
            (bookableService.capacity ?? 0) > 1;
    int defaultMaxAttendees = bookableService.capacity ??
        (bookableService.type == ReservationType.group ? 10 : 1);

    if (bookableService.capacity != null && bookableService.capacity! > 0) {
      optionsDef.putIfAbsent('allowQuantitySelection', () => true);
      optionsDef.putIfAbsent(
          'quantityDetails',
          () => {
                'min': 1,
                'max': bookableService.capacity,
                'label': bookableService.type == ReservationType.group
                    ? 'Number of People'
                    : 'Quantity'
              });
    } else if (bookableService.type != ReservationType.group) {
      optionsDef.putIfAbsent('allowQuantitySelection', () => false);
    } else if (bookableService.type == ReservationType.group &&
        bookableService.capacity == null) {
      // Group but no capacity -> default
      optionsDef.putIfAbsent('allowQuantitySelection', () => true);
      optionsDef.putIfAbsent(
          'quantityDetails',
          () => {
                'min': 1,
                'max': optionsDef['quantityDetails']?['max'] ?? 10,
                'label': 'Number of People'
              });
    }

    optionsDef.putIfAbsent(
        'allowAttendeeSelection', () => defaultAllowAttendeeSelection);
    optionsDef.putIfAbsent(
        'attendeeDetails',
        () => {
              'max': defaultMaxAttendees,
              'min': 1,
            });

    return ServiceModel(
      id: bookableService.id,
      providerId: providerId,
      name: bookableService.name,
      description: bookableService
          .description, // Removed ?? '' as it's not nullable in BookableService
      price: bookableService.price ?? 0.0,
      priceType: optionsDef['priceType'] as String? ?? 'fixed',
      currency: detailedProvider.address['country'] == 'EG' ? 'EGP' : 'USD',
      estimatedDurationMinutes: bookableService.durationMinutes,
      category: bookableService.type.displayString,
      isActive: true,
      optionsDefinition: optionsDef.isNotEmpty ? optionsDef : null,
    );
  }

  PlanModel _convertSubscriptionPlanToPlanModel(
      SubscriptionPlan subscriptionPlan,
      String providerId,
      ServiceProviderModel detailedProvider) {
    Map<String, dynamic> optionsDef = {};
    // If SubscriptionPlan model gets a `configData` field, parse it here:
    // optionsDef = Map<String, dynamic>.from(subscriptionPlan.configData ?? {});

    optionsDef.putIfAbsent('allowDateSelection', () => true);
    optionsDef.putIfAbsent('customizableNotes',
        () => "Any specific requests for your subscription?");

    String billingCycleDisplay;
    switch (subscriptionPlan.interval) {
      case PricingInterval.day:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} days'
            : 'Daily';
        break;
      case PricingInterval.week:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} weeks'
            : 'Weekly';
        break;
      case PricingInterval.month:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} months'
            : 'Monthly';
        break;
      case PricingInterval.year:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} years'
            : 'Yearly';
        break;
      // default: billingCycleDisplay = 'Per Cycle'; // Default case not needed if all enum values covered
    }

    return PlanModel(
      id: subscriptionPlan.id,
      providerId: providerId,
      name: subscriptionPlan.name,
      description: subscriptionPlan.description,
      price: subscriptionPlan.price,
      currency: detailedProvider.address['country'] == 'EG' ? 'EGP' : 'USD',
      billingCycle: billingCycleDisplay,
      features: subscriptionPlan.features,
      isActive: true,
      optionsDefinition: optionsDef.isNotEmpty ? optionsDef : null,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<ServiceProviderDetailBloc>(
          create: (bContext) => ServiceProviderDetailBloc(
            detailRepository: FirebaseServiceProviderDetailRepository(),
          )..add(LoadServiceProviderDetails(providerId: widget.providerId)),
        ),
        Provider<ReservationRepository>(
          create: (_) => FirebaseReservationRepository(),
        ),
      ],
      child:
          BlocConsumer<ServiceProviderDetailBloc, ServiceProviderDetailState>(
        listener: (context, state) {
          if (state is ServiceProviderDetailError &&
              widget.initialProviderData != null) {
            showGlobalSnackBar(
                context, "Error fetching details: ${state.message}",
                isError: true);
          }
        },
        builder: (context, state) {
          ServiceProviderModel? detailedProvider;
          ServiceProviderDisplayModel? displayData = widget.initialProviderData;
          bool isLoading = true;
          bool isFavorite = widget.initialProviderData?.isFavorite ?? false;
          List<String> headerImages = [];

          if (state is ServiceProviderDetailLoaded) {
            isFavorite = state.isFavorite;
            detailedProvider = state.provider;
            displayData = ServiceProviderDisplayModel.fromServiceProviderModel(
                detailedProvider, isFavorite);
            isLoading = false;

            if (detailedProvider.mainImageUrl != null &&
                detailedProvider.mainImageUrl!.isNotEmpty) {
              headerImages.add(detailedProvider.mainImageUrl!);
            }
            if (detailedProvider.galleryImageUrls != null) {
              headerImages.addAll(detailedProvider.galleryImageUrls!
                  .where((url) => url.isNotEmpty));
            }
            headerImages = headerImages.toSet().toList();
            if (headerImages.isEmpty) {
              if (displayData.businessLogoUrl != null &&
                  displayData.businessLogoUrl!.isNotEmpty) {
                headerImages.add(displayData.businessLogoUrl!);
              } else {
                headerImages.add('');
              }
            }
          } else if (state is ServiceProviderDetailLoading &&
              displayData != null) {
            isLoading = true;
            isFavorite = displayData.isFavorite;
            if (displayData.imageUrl != null &&
                displayData.imageUrl!.isNotEmpty) {
              headerImages.add(displayData.imageUrl!);
            } else if (displayData.businessLogoUrl != null &&
                displayData.businessLogoUrl!.isNotEmpty)
              headerImages.add(displayData.businessLogoUrl!);
            else
              headerImages.add('');
          } else if (state is ServiceProviderDetailError &&
              displayData != null) {
            isLoading = false;
            isFavorite = displayData.isFavorite;
            if (displayData.imageUrl != null &&
                displayData.imageUrl!.isNotEmpty) {
              headerImages.add(displayData.imageUrl!);
            } else if (displayData.businessLogoUrl != null &&
                displayData.businessLogoUrl!.isNotEmpty)
              headerImages.add(displayData.businessLogoUrl!);
            else
              headerImages.add('');
          } else if (state is ServiceProviderDetailInitial &&
              displayData != null) {
            isLoading = true;
            isFavorite = displayData.isFavorite;
            if (displayData.imageUrl != null &&
                displayData.imageUrl!.isNotEmpty) {
              headerImages.add(displayData.imageUrl!);
            } else if (displayData.businessLogoUrl != null &&
                displayData.businessLogoUrl!.isNotEmpty)
              headerImages.add(displayData.businessLogoUrl!);
            else
              headerImages.add('');
          }

          if (displayData == null &&
              isLoading &&
              state is! ServiceProviderDetailError) {
            return _buildLoadingShimmer(theme, widget.heroTag);
          }
          if (displayData == null && state is ServiceProviderDetailError) {
            return _buildErrorWidget(theme, state.message, () {
              context.read<ServiceProviderDetailBloc>().add(
                  LoadServiceProviderDetails(providerId: widget.providerId));
            });
          }

          if (displayData != null) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Background gradient similar to home screen
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.95),
                          AppColors.lightBackground,
                        ],
                        stops: const [0.0, 0.25, 0.5],
                      ),
                    ),
                  ),

                  // Main scrollable content
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: <Widget>[
                      // Header with image/carousel
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _ModernSliverProviderHeaderDelegate(
                          parentContext: context,
                          providerDisplayData: displayData,
                          theme: theme,
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
                            HapticFeedback.mediumImpact();
                            context
                                .read<ServiceProviderDetailBloc>()
                                .add(ToggleFavoriteStatus(
                                  providerId: displayData!.id,
                                  currentStatus: isFavorite,
                                ));
                          },
                        ),
                      ),

                      // Main content with rounded corners
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Drag handle indicator
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 4),
                                child: Container(
                                  height: 5,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              ),

                              // Loading/Error states
                              if (isLoading && detailedProvider == null)
                                const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CupertinoActivityIndicator(
                                          radius: 15)),
                                )
                              else if (detailedProvider != null)
                                _buildModernDetailContent(
                                    context, theme, detailedProvider)
                              else if (state is ServiceProviderDetailError)
                                SizedBox(
                                  height: 300,
                                  child: _buildErrorWidget(theme, state.message,
                                      () {
                                    context
                                        .read<ServiceProviderDetailBloc>()
                                        .add(LoadServiceProviderDetails(
                                            providerId: widget.providerId));
                                  }),
                                )
                              else
                                const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: Text("Loading details...",
                                          style: TextStyle(
                                              color: AppColors.secondaryText))),
                                ),

                              // Bottom padding for floating button
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Modern floating booking button
                  if (detailedProvider != null &&
                      detailedProvider.canBookOrSubscribeOnline)
                    _buildModernFloatingButton(
                        context, theme, detailedProvider),
                ],
              ),
            );
          }
          return const Center(
              child: Text("Provider data not available.",
                  style: TextStyle(color: AppColors.secondaryText)));
        },
      ),
    );
  }

  // Modern floating button with glass effect
  Widget _buildModernFloatingButton(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.9),
                    theme.colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              height: 60,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showBookingOptionsSheet(context, provider),
                  borderRadius: BorderRadius.circular(30),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.getBookingButtonText,
                          style: AppTextStyle.getButtonStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        const Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern content layout for the details screen
  Widget _buildModernDetailContent(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name and rating section
          _buildModernHeaderInfo(theme, provider),

          // Quick action buttons
          if (provider.canBookOrSubscribeOnline)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: _buildModernActionButtons(context, theme, provider),
            ),

          // Modern details sections
          _buildModernSection(
            title: "About",
            icon: CupertinoIcons.info_circle_fill,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                provider.businessDescription.isEmpty
                    ? "No description provided."
                    : provider.businessDescription,
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.primaryText,
                  height: 1.6,
                ),
              ),
            ),
          ),

          // Business insights
          if (provider.yearsInBusiness != null &&
                  provider.yearsInBusiness! > 0 ||
              provider.averageResponseTime != null)
            _buildModernSection(
              title: "Business Insights",
              icon: CupertinoIcons.graph_circle_fill,
              content: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.yearsInBusiness != null &&
                        provider.yearsInBusiness! > 0)
                      _buildModernInfoRow(
                        icon: CupertinoIcons.calendar,
                        title: "In Business Since",
                        value:
                            "${DateTime.now().year - provider.yearsInBusiness!} (${provider.yearsInBusiness} Years)",
                      ),
                    if (provider.averageResponseTime != null)
                      _buildModernInfoRow(
                        icon: CupertinoIcons.clock_fill,
                        title: "Avg. Response Time",
                        value: provider.averageResponseTime!,
                      ),
                  ],
                ),
              ),
            ),

          // Amenities section
          if (provider.amenities.isNotEmpty)
            _buildModernSection(
              title: "Facilities & Amenities",
              icon: CupertinoIcons.star_circle_fill,
              content: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _buildModernFacilities(theme, provider.amenities),
              ),
            ),

          // Services section
          if (provider.bookableServices.isNotEmpty &&
              provider.pricingModel != PricingModel.subscription)
            _buildModernSection(
              title: "Bookable Services",
              icon: CupertinoIcons.calendar_badge_plus,
              content: _buildModernServicesGrid(context, theme, provider),
            ),

          // Subscription section
          if (provider.subscriptionPlans.isNotEmpty &&
              provider.pricingModel != PricingModel.reservation)
            _buildModernSection(
              title: "Subscription Plans",
              icon: CupertinoIcons.creditcard_fill,
              content: _buildModernSubscriptionsList(context, theme, provider),
            ),

          // Location section
          _buildModernSection(
            title: "Location",
            icon: CupertinoIcons.location_circle_fill,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernInfoRow(
                    icon: CupertinoIcons.location,
                    title: "Address",
                    value:
                        "${provider.street ?? ''}${provider.street != null && (provider.city != null || provider.governorate != null) ? ', ' : ''}${provider.city ?? ''}${provider.city != null && provider.governorate != null ? ', ' : ''}${provider.governorate ?? ''}",
                  ),
                  const Gap(16),
                  _buildModernMapCard(context, theme, provider),
                ],
              ),
            ),
          ),

          // Hours section
          if (provider.openingHours.isNotEmpty &&
              provider.openingHours.values.any((day) => day.isOpen))
            _buildModernSection(
              title: "Hours",
              icon: CupertinoIcons.clock_fill,
              content: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _buildModernOpeningHours(
                    context, theme, provider.openingHours),
              ),
            ),

          // Contact section
          _buildModernSection(
            title: "Contact",
            icon: CupertinoIcons.phone_fill,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.primaryPhoneNumber != null)
                    _buildModernContactButton(
                      context: context,
                      icon: CupertinoIcons.phone_fill,
                      label: provider.primaryPhoneNumber!,
                      action: () => _launchUrlHelper(
                          context, provider.primaryPhoneNumber, "Call"),
                    ),
                  if (provider.primaryEmail != null)
                    _buildModernContactButton(
                      context: context,
                      icon: CupertinoIcons.envelope_fill,
                      label: provider.primaryEmail!,
                      action: () => _launchUrlHelper(
                          context, provider.primaryEmail, "Email"),
                    ),
                  if (provider.website != null)
                    _buildModernContactButton(
                      context: context,
                      icon: CupertinoIcons.globe,
                      label: provider.website!,
                      action: () => _launchUrlHelper(
                          context, provider.website, "Website"),
                    ),
                  if (provider.paymentMethodsAccepted != null &&
                      provider.paymentMethodsAccepted!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildModernInfoRow(
                        icon: CupertinoIcons.money_dollar_circle_fill,
                        title: "Payment Methods",
                        value: provider.paymentMethodsAccepted!.join(', '),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern header with provider name and rating
  Widget _buildModernHeaderInfo(
      ThemeData theme, ServiceProviderModel provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider name
          Text(
            provider.businessName,
            style: AppTextStyle.getHeadlineTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),

          const Gap(8),

          // Rating and category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.star_fill,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const Gap(4),
                    Text(
                      "${provider.rating.toStringAsFixed(1)} (${provider.ratingCount})",
                      style: AppTextStyle.getSmallStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.category,
                  style: AppTextStyle.getSmallStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              if (provider.subCategory != null &&
                  provider.subCategory!.isNotEmpty) ...[
                const Gap(10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.subCategory!,
                    style: AppTextStyle.getSmallStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Gap(8),

          // Location row
          Row(
            children: [
              const Icon(
                CupertinoIcons.location_solid,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const Gap(6),
              Expanded(
                child: Text(
                  "${provider.city ?? ''}${provider.governorate != null && provider.city != null ? ', ' : ''}${provider.governorate ?? 'Location not specified'}",
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(ThemeData theme, String heroTag) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.95),
                  AppColors.lightBackground,
                ],
                stops: const [0.0, 0.25, 0.5],
              ),
            ),
          ),

          Column(
            children: [
              // Header image shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: MediaQuery.of(context).size.width * (9 / 16) +
                      MediaQuery.of(context).padding.top,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),

              // Content shimmer
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const Gap(20),

                        // Title shimmer
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 28,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const Gap(12),

                        // Rating shimmer
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Row(
                            children: [
                              Container(
                                height: 24,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const Gap(12),
                              Container(
                                height: 24,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(20),

                        // Content sections shimmer
                        for (int i = 0; i < 4; i++) ...[
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 24,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const Gap(24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
      ThemeData theme, String message, VoidCallback onRetry) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.95),
                  AppColors.lightBackground,
                ],
                stops: const [0.0, 0.25, 0.5],
              ),
            ),
          ),

          // Error content
          Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.redColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      color: AppColors.redColor,
                      size: 32,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    "Error Loading Details",
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    message,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(24),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern action buttons
  Widget _buildModernActionButtons(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    List<Widget> buttons = [];

    if (provider.primaryPhoneNumber != null &&
        provider.primaryPhoneNumber!.isNotEmpty) {
      buttons.add(_buildModernActionButton(
        icon: CupertinoIcons.phone_fill,
        label: "Call",
        color: AppColors.greenColor,
        onTap: () =>
            _launchUrlHelper(context, provider.primaryPhoneNumber, "Call"),
      ));
    }

    if (provider.location != null) {
      buttons.add(_buildModernActionButton(
        icon: CupertinoIcons.map_fill,
        label: "Directions",
        color: AppColors.orangeColor,
        onTap: () {
          final lat = provider.location!.latitude;
          final lon = provider.location!.longitude;
          final url =
              'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
          _launchUrlHelper(context, url, "Map");
        },
      ));
    }

    if (provider.website != null && provider.website!.isNotEmpty) {
      buttons.add(_buildModernActionButton(
        icon: CupertinoIcons.globe,
        label: "Website",
        color: AppColors.cyanColor,
        onTap: () => _launchUrlHelper(context, provider.website, "Website"),
      ));
    }

    if (provider.primaryEmail != null && provider.primaryEmail!.isNotEmpty) {
      buttons.add(_buildModernActionButton(
        icon: CupertinoIcons.envelope_fill,
        label: "Email",
        color: AppColors.purpleColor,
        onTap: () => _launchUrlHelper(context, provider.primaryEmail, "Email"),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: buttons,
    );
  }

  // Modern action button with icon
  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Modern section with heading
  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 16,
                  ),
                ),
              ),
              const Gap(12),
              Text(
                title,
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Optional divider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
        ),
        content,
      ],
    );
  }

  // Modern info row component
  Widget _buildModernInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: AppTextStyle.getbodyStyle(
                    color: AppColors.primaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern facilities chips
  Widget _buildModernFacilities(ThemeData theme, List<String> amenities) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: amenities.map((amenity) {
        final icon = AppIcons.getIconForAmenity(amenity);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primaryColor,
              ),
              const Gap(6),
              Text(
                amenity,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Modern services grid
  Widget _buildModernServicesGrid(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.bookableServices.length,
        itemBuilder: (context, index) {
          final service = provider.bookableServices[index];
          return _buildModernServiceCard(
            context: context,
            service: service,
            provider: provider,
            index: index,
          );
        },
      ),
    );
  }

  // Modern service card
  Widget _buildModernServiceCard({
    required BuildContext context,
    required BookableService service,
    required ServiceProviderModel provider,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToOptionsConfiguration(
            context,
            service: service,
            provider: provider,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name and arrow
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: AppColors.primaryColor,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                if (service.description.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    service.description,
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Gap(12),

                // Service details chips
                Row(
                  children: [
                    if (service.durationMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.clock_fill,
                              size: 12,
                              color: AppColors.secondaryColor,
                            ),
                            const Gap(4),
                            Text(
                              "${service.durationMinutes} min",
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Gap(8),
                    if (service.price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              size: 12,
                              color: AppColors.primaryColor,
                            ),
                            const Gap(4),
                            Text(
                              "EGP ${service.price!.toStringAsFixed(0)}",
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern subscriptions list
  Widget _buildModernSubscriptionsList(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.subscriptionPlans.length,
        itemBuilder: (context, index) {
          final plan = provider.subscriptionPlans[index];
          return _buildModernSubscriptionCard(
            context: context,
            plan: plan,
            provider: provider,
          );
        },
      ),
    );
  }

  // Modern subscription card
  Widget _buildModernSubscriptionCard({
    required BuildContext context,
    required SubscriptionPlan plan,
    required ServiceProviderModel provider,
  }) {
    final intervalStr =
        "${plan.intervalCount > 1 ? '${plan.intervalCount} ' : ''}${plan.interval.name}${plan.intervalCount > 1 ? 's' : ''}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToOptionsConfiguration(
            context,
            planData: plan,
            provider: provider,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: AppTextStyle.getTitleStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (plan.description.isNotEmpty) ...[
                            const Gap(6),
                            Text(
                              plan.description,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "EGP ${plan.price.toStringAsFixed(0)}",
                          style: AppTextStyle.getTitleStyle(
                            color: AppColors.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "/ $intervalStr",
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (plan.features.isNotEmpty) ...[
                  const Gap(16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plan.features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 12,
                              color: AppColors.greenColor,
                            ),
                            const Gap(4),
                            Text(
                              feature,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
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

  // Modern map card
  Widget _buildModernMapCard(
      BuildContext context, ThemeData theme, ServiceProviderModel provider) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.map_fill,
                          size: 40,
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                        const Gap(8),
                        Text(
                          "Map View",
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (provider.location != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final lat = provider.location!.latitude;
                        final lon = provider.location!.longitude;
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                        _launchUrlHelper(context, url, "Map");
                      },
                      icon: const Icon(
                        CupertinoIcons.arrow_up_right_square_fill,
                        size: 14,
                      ),
                      label: const Text("Open Maps"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyle.getSmallStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern opening hours
  Widget _buildModernOpeningHours(BuildContext context, ThemeData theme,
      Map<String, OpeningHoursDay> hoursMap) {
    final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
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
        final hours = hoursMap[day.toLowerCase()];
        final bool isToday = day == today;
        final String displayDay = day[0].toUpperCase() + day.substring(1);
        String displayHours;

        if (hours == null ||
            !hours.isOpen ||
            hours.startTime == null ||
            hours.endTime == null) {
          displayHours = "Closed";
        } else {
          final localizations = MaterialLocalizations.of(context);
          final startFormatted = localizations.formatTimeOfDay(
            hours.startTime!,
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );
          final endFormatted = localizations.formatTimeOfDay(
            hours.endTime!,
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );
          displayHours = "$startFormatted - $endFormatted";
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primaryColor.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? AppColors.primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToday) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hours != null && hours.isOpen
                            ? AppColors.greenColor
                            : AppColors.redColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                  ],
                  Text(
                    displayDay,
                    style: AppTextStyle.getbodyStyle(
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      color: isToday
                          ? AppColors.primaryColor
                          : AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              Text(
                displayHours,
                style: AppTextStyle.getbodyStyle(
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                  color: (hours == null || !hours.isOpen)
                      ? AppColors.redColor.withOpacity(0.7)
                      : (isToday
                          ? AppColors.primaryColor
                          : AppColors.primaryText),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Modern contact button
  Widget _buildModernContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern header delegate for the service provider detail screen
class _ModernSliverProviderHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final BuildContext parentContext;
  final ServiceProviderDisplayModel providerDisplayData;
  final ThemeData theme;
  final String heroTag;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final List<String> headerImages;
  final int carouselIndex;
  final Function(int index, CarouselPageChangedReason reason)
      onCarouselPageChanged;

  _ModernSliverProviderHeaderDelegate({
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

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double topSafeArea = MediaQuery.of(parentContext).padding.top;
    final double currentExtent = maxExtent - shrinkOffset;
    final double progress = (1.0 - currentExtent / maxExtent).clamp(0.0, 1.0);

    // Opacity values for smooth transitions
    final double imageOpacity = (1.0 - progress * 1.2).clamp(0.0, 1.0);
    final double titleOpacity = (progress * 1.5 - 0.3).clamp(0.0, 1.0);

    final bool noImagesAvailable = headerImages.isEmpty ||
        (headerImages.length == 1 && headerImages.first.isEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image/carousel with hero animation
        Positioned.fill(
          child: Opacity(
            opacity: imageOpacity,
            child: Hero(
              tag: heroTag,
              child: noImagesAvailable
                  ? Container(
                      color: AppColors.primaryColor.withOpacity(0.8),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.photo_fill,
                          color: Colors.white.withOpacity(0.3),
                          size: 60,
                        ),
                      ),
                    )
                  : CarouselSlider.builder(
                      itemCount: headerImages.length,
                      itemBuilder: (carouselContext, index, realIndex) {
                        final imageUrl = headerImages[index];
                        if (imageUrl.isEmpty) {
                          return Container(
                            color: AppColors.primaryColor.withOpacity(0.8),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.photo_fill,
                                color: Colors.white.withOpacity(0.3),
                                size: 60,
                              ),
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (c, u) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (c, u, e) => Container(
                            color: AppColors.primaryColor.withOpacity(0.8),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.photo_fill,
                                color: Colors.white.withOpacity(0.3),
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: double.infinity,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: headerImages.length > 1,
                        autoPlay: headerImages.length > 1,
                        autoPlayInterval: const Duration(seconds: 5),
                        autoPlayAnimationDuration:
                            const Duration(milliseconds: 800),
                        autoPlayCurve: Curves.fastOutSlowIn,
                        onPageChanged: onCarouselPageChanged,
                        initialPage: carouselIndex,
                      ),
                    ),
            ),
          ),
        ),

        // Gradient overlay for better readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(imageOpacity * 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Header bar with title when scrolled
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: topSafeArea + kToolbarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor.withOpacity(titleOpacity * 0.9),
                  AppColors.primaryColor.withOpacity(titleOpacity * 0.7),
                  AppColors.primaryColor.withOpacity(0),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topSafeArea),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered title
                  Opacity(
                    opacity: titleOpacity,
                    child: Text(
                      providerDisplayData.businessName,
                      style: AppTextStyle.getTitleStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Back button
                  Positioned(
                    left: 4,
                    child: _buildHeaderButton(
                      icon: CupertinoIcons.chevron_left,
                      onTap: () => Navigator.pop(parentContext),
                      color: progress > 0.3 && titleOpacity > 0
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),

                  // Action buttons
                  Positioned(
                    right: 4,
                    child: Row(
                      children: [
                        _buildHeaderButton(
                          icon: CupertinoIcons.share,
                          onTap: () {
                            showGlobalSnackBar(
                                parentContext, "Share feature coming soon!");
                          },
                          color: progress > 0.3 && titleOpacity > 0
                              ? Colors.white
                              : Colors.white,
                        ),
                        _buildHeaderButton(
                          icon: isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          onTap: onFavoriteToggle,
                          color: isFavorite
                              ? Colors.redAccent
                              : (progress > 0.3 && titleOpacity > 0
                                  ? Colors.white
                                  : Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Carousel dots indicator
        if (!noImagesAvailable && headerImages.length > 1 && imageOpacity > 0.5)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: imageOpacity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DotsIndicator(
                    dotsCount: headerImages.length,
                    position: carouselIndex.toDouble(),
                    decorator: DotsDecorator(
                      size: const Size.square(6.0),
                      activeSize: const Size(18.0, 6.0),
                      activeShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      color: Colors.white.withOpacity(0.5),
                      activeColor: Colors.white,
                      spacing: const EdgeInsets.symmetric(horizontal: 3.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Modern header button
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: 22,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashRadius: 20,
      ),
    );
  }

  @override
  double get maxExtent =>
      MediaQuery.of(parentContext).size.width * (9 / 16) +
      MediaQuery.of(parentContext).padding.top;

  @override
  double get minExtent =>
      kToolbarHeight + MediaQuery.of(parentContext).padding.top;

  @override
  bool shouldRebuild(
      covariant _ModernSliverProviderHeaderDelegate oldDelegate) {
    return parentContext != oldDelegate.parentContext ||
        providerDisplayData != oldDelegate.providerDisplayData ||
        theme != oldDelegate.theme ||
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
      (bookableServices.isNotEmpty || supportedReservationTypes.isNotEmpty);

  bool get hasSubscriptionsEnabled =>
      (pricingModel == PricingModel.subscription ||
          pricingModel == PricingModel.hybrid) &&
      subscriptionPlans.isNotEmpty;

  String get getBookingButtonText {
    if (pricingModel == PricingModel.reservation) return "Book / View Options";
    if (pricingModel == PricingModel.subscription) {
      return "View Subscription Plans";
    }
    if (pricingModel == PricingModel.hybrid) return "Book or Subscribe";
    return "Contact Provider";
  }
}
