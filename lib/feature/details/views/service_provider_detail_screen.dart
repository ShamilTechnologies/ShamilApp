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
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show ReservationType, ReservationTypeExtension;

import 'package:shamil_mobile_app/feature/details/views/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/modern_options_configuration_screen.dart';
import 'package:shamil_mobile_app/feature/details/widgets/options_bottom_sheet.dart'
    as options_sheet;
import 'package:shamil_mobile_app/feature/details/views/provider_services_screen.dart';

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
    extends State<ServiceProviderDetailScreen> with TickerProviderStateMixin {
  int _carouselCurrentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Enhanced animation controllers for premium design
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _floatingButtonController;
  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingButtonAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _pages = ['Overview', 'Services', 'Contact'];

  @override
  void initState() {
    super.initState();

    // Initialize premium animation controllers
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Premium animations setup
    _heroAnimation = CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutCubic,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _floatingButtonAnimation = CurvedAnimation(
      parent: _floatingButtonController,
      curve: Curves.elasticOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingButtonController,
      curve: Curves.elasticOut,
    ));

    // Start premium animations with staggered timing
    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _floatingButtonController.forward();
    });
  }

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
    if (!provider.canBookOrSubscribeOnline) {
      showGlobalSnackBar(parentContext,
          "Online booking/subscription not available for this provider.",
          isError: false);
      return;
    }

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetBuilderContext) {
        return MultiBlocProvider(
          providers: [
            if (provider.hasSubscriptionsEnabled)
              BlocProvider<SubscriptionBloc>(
                  create: (_) =>
                      SubscriptionBloc()..add(ResetSubscriptionFlow())),
            if (provider.hasReservationsEnabled)
              BlocProvider<ReservationBloc>(
                  create: (_) => ReservationBloc(
                        provider: provider,
                        reservationRepository:
                            parentContext.read<ReservationRepository>(),
                      )..add(ResetReservationFlow(provider: provider))),
          ],
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (BuildContext scrollableSheetContext,
                ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.98),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, -8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Premium Handle
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondaryColor
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: options_sheet.OptionsBottomSheetContent(
                        provider: provider,
                        scrollController: scrollController,
                      ),
                    ),
                  ],
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
                  BlocProvider.value(
                      value: BlocProvider.of<SocialBloc>(context)),
                  BlocProvider.value(value: BlocProvider.of<AuthBloc>(context)),
                ],
                child: ModernOptionsConfigurationScreen(
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
    final String serviceTypeKey = bookableService.type.typeString;
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
      description: bookableService.description,
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
    _pageController.dispose();
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _floatingButtonController.dispose();
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
            return _buildPremiumLoadingScreen();
          }
          if (displayData == null && state is ServiceProviderDetailError) {
            return _buildPremiumErrorScreen(state.message, () {
              context.read<ServiceProviderDetailBloc>().add(
                  LoadServiceProviderDetails(providerId: widget.providerId));
            });
          }

          if (displayData != null) {
            return Theme(
              data: theme.copyWith(
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: ZoomPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              child: Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                extendBodyBehindAppBar: true,
                body: FadeTransition(
                  opacity: _heroAnimation,
                  child: NestedScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Container(
                            color: const Color(0xFFF8FAFC),
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top +
                                  16, // Status bar + padding
                              left: 16,
                              right: 16,
                              bottom: 20,
                            ),
                            child: _buildSquareHeroSection(
                                headerImages, displayData!, isFavorite),
                          ),
                        ),
                      ];
                    },
                    body: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _contentAnimation,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      const Gap(20), // Top spacing

                                      // Premium Business Info Header
                                      _buildPremiumBusinessHeader(
                                          displayData, detailedProvider),

                                      // Premium Quick Actions Bar
                                      _buildPremiumQuickActions(
                                          context, detailedProvider),

                                      // Premium Main Content
                                      _buildPremiumMainContent(context,
                                          displayData, detailedProvider),

                                      const Gap(
                                          120), // Space for floating button
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Premium Floating Action Button
                floatingActionButton: detailedProvider != null &&
                        detailedProvider.canBookOrSubscribeOnline
                    ? ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildPremiumFloatingButton(
                            context, detailedProvider),
                      )
                    : null,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
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

  // Square Hero Section
  Widget _buildSquareHeroSection(List<String> headerImages,
      ServiceProviderDisplayModel displayData, bool isFavorite) {
    final bool noImagesAvailable = headerImages.isEmpty ||
        (headerImages.length == 1 && headerImages.first.isEmpty);

    final screenWidth = MediaQuery.of(context).size.width;
    final containerSize = screenWidth - 32; // Account for left/right padding

    return Hero(
      tag: widget.heroTag,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main Image Container
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: noImagesAvailable
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor,
                              AppColors.secondaryColor,
                            ],
                          ),
                        ),
                      )
                    : CarouselSlider.builder(
                        itemCount: headerImages.length,
                        itemBuilder: (context, index, realIndex) {
                          final imageUrl = headerImages[index];
                          if (imageUrl.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.secondaryColor,
                                  ],
                                ),
                              ),
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (c, u) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.3),
                                    AppColors.secondaryColor.withOpacity(0.3),
                                  ],
                                ),
                              ),
                              child: Shimmer.fromColors(
                                baseColor: Colors.white.withOpacity(0.1),
                                highlightColor: Colors.white.withOpacity(0.3),
                                child: Container(),
                              ),
                            ),
                            errorWidget: (c, u, e) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.secondaryColor,
                                  ],
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
                          autoPlayInterval: const Duration(seconds: 4),
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                          autoPlayCurve: Curves.easeInOutQuad,
                          onPageChanged: (index, reason) {
                            if (mounted) {
                              setState(() {
                                _carouselCurrentIndex = index;
                              });
                            }
                          },
                          initialPage: _carouselCurrentIndex,
                        ),
                      ),
              ),
            ),

            // Enhanced Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Floating Navigation Buttons (Top)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Floating Back Button
                  _buildFloatingButton(
                    child: const Icon(
                      CupertinoIcons.chevron_left,
                      color: AppColors.primaryText,
                      size: 20,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),

                  Row(
                    children: [
                      // Floating Like Button
                      _buildFloatingButton(
                        child: Icon(
                          isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color:
                              isFavorite ? Colors.red : AppColors.primaryText,
                          size: 20,
                        ),
                        onTap: () =>
                            _handleFavoriteToggle(displayData, isFavorite),
                      ),
                      const Gap(8),
                      // Floating Share Button
                      _buildFloatingButton(
                        child: const Icon(
                          CupertinoIcons.share,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Photo Counter (only if multiple images) - moved to top
            if (headerImages.length > 1)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.9),
                          AppColors.secondaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "${_carouselCurrentIndex + 1}/${headerImages.length}",
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),

            // Business Info Row (bottom left - compact and adaptive)
            Positioned(
              bottom: 12,
              left: 12,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width -
                      180, // Ensure more right padding
                ),
                child: IntrinsicWidth(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.4),
                          AppColors.secondaryColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Business Logo
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: displayData.businessLogoUrl != null &&
                                      displayData.businessLogoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: displayData.businessLogoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) =>
                                          _buildModernLogoBadgePlaceholder(
                                              displayData),
                                      errorWidget: (c, u, e) =>
                                          _buildModernLogoBadgePlaceholder(
                                              displayData),
                                    )
                                  : _buildModernLogoBadgePlaceholder(
                                      displayData),
                            ),
                          ),

                          const Gap(10),

                          // Business Name and Category
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Business Name
                                Text(
                                  displayData.businessName,
                                  style: AppTextStyle.getHeadlineTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(3),
                                // Business Category
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    displayData.businessCategory,
                                    style: AppTextStyle.getSmallStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Rating Badge (bottom right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.star_fill,
                      color: Colors.white,
                      size: 14,
                    ),
                    const Gap(4),
                    Text(
                      displayData.averageRating.toStringAsFixed(1),
                      style: AppTextStyle.getTitleStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Button with Shadow
  Widget _buildFloatingButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(child: child),
        ),
      ),
    );
  }

  // Modern Logo Badge Placeholder
  Widget _buildModernLogoBadgePlaceholder(
      ServiceProviderDisplayModel displayData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          displayData.businessName.substring(0, 1).toUpperCase(),
          style: AppTextStyle.getTitleStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // Premium Business Header (Location Only)
  Widget _buildPremiumBusinessHeader(ServiceProviderDisplayModel displayData,
      ServiceProviderModel? detailedProvider) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: displayData.city.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orangeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.orangeColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orangeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        displayData.city,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // Premium Quick Actions
  Widget _buildPremiumQuickActions(
      BuildContext context, ServiceProviderModel? detailedProvider) {
    if (detailedProvider == null) return const SizedBox.shrink();

    List<Widget> actionCards = [];

    if (detailedProvider.primaryPhoneNumber != null) {
      actionCards.add(_buildPremiumActionCard(
        icon: CupertinoIcons.phone_fill,
        label: "Call",
        color: AppColors.greenColor,
        onTap: () => _launchUrlHelper(
            context, detailedProvider.primaryPhoneNumber, "Call"),
      ));
    }

    if (detailedProvider.location != null) {
      actionCards.add(_buildPremiumActionCard(
        icon: CupertinoIcons.map_fill,
        label: "Directions",
        color: AppColors.orangeColor,
        onTap: () {
          final lat = detailedProvider.location!.latitude;
          final lon = detailedProvider.location!.longitude;
          final url =
              'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
          _launchUrlHelper(context, url, "Map");
        },
      ));
    }

    if (detailedProvider.website != null) {
      actionCards.add(_buildPremiumActionCard(
        icon: CupertinoIcons.globe,
        label: "Website",
        color: AppColors.cyanColor,
        onTap: () =>
            _launchUrlHelper(context, detailedProvider.website, "Website"),
      ));
    }

    if (detailedProvider.primaryEmail != null) {
      actionCards.add(_buildPremiumActionCard(
        icon: CupertinoIcons.envelope_fill,
        label: "Email",
        color: AppColors.purpleColor,
        onTap: () =>
            _launchUrlHelper(context, detailedProvider.primaryEmail, "Email"),
      ));
    }

    if (actionCards.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actionCards.map((card) => Expanded(child: card)).toList(),
      ),
    );
  }

  // Premium Action Card
  Widget _buildPremiumActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  label,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Main Content
  Widget _buildPremiumMainContent(
      BuildContext context,
      ServiceProviderDisplayModel displayData,
      ServiceProviderModel? detailedProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          if (detailedProvider?.businessDescription.isNotEmpty == true)
            _buildPremiumSectionCard(
              title: "About",
              icon: CupertinoIcons.info_circle_fill,
              iconColor: AppColors.primaryColor,
              child: Text(
                detailedProvider!.businessDescription,
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.primaryText,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ),

          const Gap(20),

          // Services Section with Navigation
          if (detailedProvider?.bookableServices.isNotEmpty == true ||
              detailedProvider?.subscriptionPlans.isNotEmpty == true)
            _buildPremiumServicesPreview(context, detailedProvider!),

          const Gap(20),

          // Amenities Section
          if (detailedProvider?.amenities.isNotEmpty == true)
            _buildPremiumSectionCard(
              title: "Facilities & Amenities",
              icon: CupertinoIcons.star_circle_fill,
              iconColor: AppColors.secondaryColor,
              child: _buildPremiumFacilities(detailedProvider!.amenities),
            ),

          const Gap(20),

          // Hours Section
          if (detailedProvider?.openingHours.isNotEmpty == true &&
              detailedProvider!.openingHours.values.any((day) => day.isOpen))
            _buildPremiumSectionCard(
              title: "Opening Hours",
              icon: CupertinoIcons.clock_fill,
              iconColor: AppColors.accentColor,
              child: _buildPremiumOpeningHours(
                  context, detailedProvider.openingHours),
            ),

          const Gap(20),

          // Contact Section
          _buildPremiumContactSection(context, detailedProvider),
        ],
      ),
    );
  }

  // Premium Floating Button
  Widget _buildPremiumFloatingButton(
      BuildContext context, ServiceProviderModel provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _navigateToServicesScreen(context, provider);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        provider.pricingModel == PricingModel.reservation
                            ? CupertinoIcons.calendar_badge_plus
                            : provider.pricingModel == PricingModel.subscription
                                ? CupertinoIcons.creditcard_fill
                                : CupertinoIcons.star_circle_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Text(
                    "View Services & Plans",
                    style: AppTextStyle.getButtonStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(12),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_right,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Navigate to Services Screen
  void _navigateToServicesScreen(
      BuildContext context, ServiceProviderModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderServicesScreen(provider: provider),
      ),
    );
  }

  // Fix the null safety issue
  void _handleFavoriteToggle(
      ServiceProviderDisplayModel? displayData, bool isFavorite) {
    if (displayData?.id != null) {
      HapticFeedback.mediumImpact();
      context.read<ServiceProviderDetailBloc>().add(ToggleFavoriteStatus(
            providerId: displayData!.id,
            currentStatus: isFavorite,
          ));
    }
  }

  // Premium Section Card
  Widget _buildPremiumSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.08),
                  iconColor.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [iconColor, iconColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Gap(16),
                Text(
                  title,
                  style: AppTextStyle.getTitleStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Premium Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  // Premium Services Preview
  Widget _buildPremiumServicesPreview(
      BuildContext context, ServiceProviderModel provider) {
    return _buildPremiumSectionCard(
      title: "Services & Plans",
      icon: CupertinoIcons.square_grid_2x2_fill,
      iconColor: AppColors.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.bookableServices.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bookable Services",
                          style: AppTextStyle.getbodyStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          "${provider.bookableServices.length} services available",
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],
          if (provider.subscriptionPlans.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentColor.withOpacity(0.1),
                    AppColors.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentColor,
                          AppColors.secondaryColor
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Subscription Plans",
                          style: AppTextStyle.getbodyStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          "${provider.subscriptionPlans.length} plans available",
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.secondaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_right_circle_fill,
                    color: AppColors.primaryColor,
                    size: 16,
                  ),
                  const Gap(8),
                  Text(
                    "View All Services & Plans",
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  // Premium Facilities
  Widget _buildPremiumFacilities(List<String> amenities) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: amenities.map((amenity) {
        final icon = AppIcons.getIconForAmenity(amenity);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryColor.withOpacity(0.12),
                AppColors.secondaryColor.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondaryColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(8),
              Text(
                amenity,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Premium Opening Hours
  Widget _buildPremiumOpeningHours(
      BuildContext context, Map<String, OpeningHoursDay> hoursMap) {
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
      children: daysOrder.take(4).map((day) {
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
            gradient: LinearGradient(
              colors: isToday
                  ? [
                      AppColors.accentColor.withOpacity(0.15),
                      AppColors.accentColor.withOpacity(0.05),
                    ]
                  : [
                      Colors.grey.shade50,
                      Colors.grey.shade100,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? AppColors.accentColor.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    displayDay,
                    style: AppTextStyle.getbodyStyle(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                      color: isToday
                          ? AppColors.accentColor
                          : AppColors.primaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (hours == null || !hours.isOpen)
                      ? AppColors.redColor.withOpacity(0.1)
                      : AppColors.greenColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayHours,
                  style: AppTextStyle.getbodyStyle(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: (hours == null || !hours.isOpen)
                        ? AppColors.redColor
                        : (isToday
                            ? AppColors.accentColor
                            : AppColors.primaryText),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Premium Contact Section
  Widget _buildPremiumContactSection(
      BuildContext context, ServiceProviderModel? detailedProvider) {
    if (detailedProvider == null) return const SizedBox.shrink();

    return _buildPremiumSectionCard(
      title: "Contact Information",
      icon: CupertinoIcons.phone_fill,
      iconColor: AppColors.greenColor,
      child: Column(
        children: [
          if (detailedProvider.primaryPhoneNumber != null)
            _buildPremiumContactButton(
              context: context,
              icon: CupertinoIcons.phone_fill,
              label: detailedProvider.primaryPhoneNumber!,
              subtitle: "Tap to call",
              color: AppColors.greenColor,
              action: () => _launchUrlHelper(
                  context, detailedProvider.primaryPhoneNumber, "Call"),
            ),
          if (detailedProvider.primaryEmail != null)
            _buildPremiumContactButton(
              context: context,
              icon: CupertinoIcons.envelope_fill,
              label: detailedProvider.primaryEmail!,
              subtitle: "Tap to email",
              color: AppColors.purpleColor,
              action: () => _launchUrlHelper(
                  context, detailedProvider.primaryEmail, "Email"),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            action();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        subtitle,
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.secondaryText,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Loading Screen
  Widget _buildPremiumLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Hero section shimmer
            Container(
              height: 380,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.3),
                    AppColors.secondaryColor.withOpacity(0.3),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.3),
                child: Container(),
              ),
            ),

            // Premium Content shimmer
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Business info shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const Gap(20),

                      // Action cards shimmer
                      Row(
                        children: List.generate(
                            4,
                            (index) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                      ),

                      const Gap(20),

                      // Content cards shimmer
                      for (int i = 0; i < 3; i++) ...[
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        const Gap(20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Error Screen
  Widget _buildPremiumErrorScreen(String message, VoidCallback onRetry) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildFloatingButton(
                    child: const Icon(
                      CupertinoIcons.chevron_left,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      "Error Loading Details",
                      style: AppTextStyle.getHeadlineTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Premium Error Content
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.redColor.withOpacity(0.2),
                              AppColors.redColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.redColor,
                          size: 40,
                        ),
                      ),
                      const Gap(24),
                      Text(
                        "Something went wrong",
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        message,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.secondaryText,
                          height: 1.6,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(32),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.secondaryColor
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              onRetry();
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Center(
                              child: Text(
                                "Try Again",
                                style: AppTextStyle.getButtonStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
