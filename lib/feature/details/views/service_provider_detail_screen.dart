// lib/feature/details/views/service_provider_detail_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/reservation_repository.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

import 'package:shamil_mobile_app/feature/details/views/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/details/views/provider_services_screen.dart';

import 'widgets/hero_section.dart';
import 'widgets/content_sections.dart';
import 'widgets/booking_flow_handler.dart';

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

  // Enhanced animation controllers for premium design
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _floatingButtonController;
  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingButtonAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
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
  }

  void _startAnimationSequence() {
    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _floatingButtonController.forward();
    });
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
        listener: _handleStateChanges,
        builder: (context, state) => _buildScreenContent(context, state, theme),
      ),
    );
  }

  void _handleStateChanges(
      BuildContext context, ServiceProviderDetailState state) {
    if (state is ServiceProviderDetailError &&
        widget.initialProviderData != null) {
      showGlobalSnackBar(
        context,
        "Error fetching details: ${state.message}",
        isError: true,
      );
    }
  }

  Widget _buildScreenContent(
      BuildContext context, ServiceProviderDetailState state, ThemeData theme) {
    final screenData = _extractScreenData(state);

    if (screenData == null) {
      return _buildErrorOrLoadingState(state);
    }

    return _buildMainScreen(context, theme, screenData);
  }

  ScreenData? _extractScreenData(ServiceProviderDetailState state) {
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
      headerImages = _buildHeaderImages(detailedProvider, displayData);
    } else if (state is ServiceProviderDetailLoading && displayData != null) {
      isLoading = true;
      isFavorite = displayData.isFavorite;
      headerImages = _buildHeaderImages(null, displayData);
    } else if (state is ServiceProviderDetailError && displayData != null) {
      isLoading = false;
      isFavorite = displayData.isFavorite;
      headerImages = _buildHeaderImages(null, displayData);
    } else if (state is ServiceProviderDetailInitial && displayData != null) {
      isLoading = true;
      isFavorite = displayData.isFavorite;
      headerImages = _buildHeaderImages(null, displayData);
    }

    if (displayData == null) return null;

    return ScreenData(
      displayData: displayData,
      detailedProvider: detailedProvider,
      isLoading: isLoading,
      isFavorite: isFavorite,
      headerImages: headerImages,
    );
  }

  List<String> _buildHeaderImages(ServiceProviderModel? detailedProvider,
      ServiceProviderDisplayModel? displayData) {
    List<String> headerImages = [];

    if (detailedProvider != null) {
      if (detailedProvider.mainImageUrl != null &&
          detailedProvider.mainImageUrl!.isNotEmpty) {
        headerImages.add(detailedProvider.mainImageUrl!);
      }
      if (detailedProvider.galleryImageUrls != null) {
        headerImages.addAll(
            detailedProvider.galleryImageUrls!.where((url) => url.isNotEmpty));
      }
      headerImages = headerImages.toSet().toList();
    }

    if (headerImages.isEmpty) {
      if (displayData?.businessLogoUrl != null &&
          displayData!.businessLogoUrl!.isNotEmpty) {
        headerImages.add(displayData.businessLogoUrl!);
      } else if (displayData?.imageUrl != null &&
          displayData!.imageUrl!.isNotEmpty) {
        headerImages.add(displayData.imageUrl!);
      } else {
        headerImages.add('');
      }
    }

    return headerImages;
  }

  Widget _buildErrorOrLoadingState(ServiceProviderDetailState state) {
    if (state is ServiceProviderDetailInitial ||
        (state is ServiceProviderDetailLoading &&
            widget.initialProviderData == null)) {
      return _buildProfessionalLoadingState();
    }

    if (state is ServiceProviderDetailError &&
        widget.initialProviderData == null) {
      return _buildProfessionalErrorState(state.message, () {
        context
            .read<ServiceProviderDetailBloc>()
            .add(LoadServiceProviderDetails(providerId: widget.providerId));
      });
    }

    return const Center(
      child: Text(
        "Provider data not available.",
        style: TextStyle(color: AppColors.secondaryText),
      ),
    );
  }

  Widget _buildMainScreen(
      BuildContext context, ThemeData theme, ScreenData screenData) {
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
        backgroundColor: AppColors.deepSpaceNavy,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(color: AppColors.deepSpaceNavy),
          child: Stack(
            children: [
              ..._buildAmbientDesign(),
              _buildScrollableContent(screenData),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(screenData),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildScrollableContent(ScreenData screenData) {
    return FadeTransition(
      opacity: _heroAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            HeroSection(
              headerImages: screenData.headerImages,
              displayData: screenData.displayData,
              isFavorite: screenData.isFavorite,
              heroTag: widget.heroTag,
              carouselCurrentIndex: _carouselCurrentIndex,
              pageController: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _carouselCurrentIndex = index);
                  HapticFeedback.lightImpact();
                }
              },
              onFavoriteToggle: () => _handleFavoriteToggle(
                  screenData.displayData, screenData.isFavorite),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.deepSpaceNavy,
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: ContentSections(
                    displayData: screenData.displayData,
                    detailedProvider: screenData.detailedProvider,
                    onLaunchUrl: _launchUrlHelper,
                    onNavigateToServices: () => _navigateToServicesScreen(
                        context, screenData.detailedProvider!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ScreenData screenData) {
    if (screenData.detailedProvider != null &&
        screenData.detailedProvider!.canBookOrSubscribeOnlineInDetail) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: ModernFloatingCTA(
          provider: screenData.detailedProvider!,
          onTap: () => BookingFlowHandler.showBookingOptions(
              context, screenData.detailedProvider!),
        ),
      );
    }
    return null;
  }

  List<Widget> _buildAmbientDesign() {
    return [
      Positioned(
        top: 80,
        right: -120,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                AppColors.tealColor.withOpacity(0.15),
                AppColors.tealColor.withOpacity(0.08),
                AppColors.tealColor.withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        top: 300,
        left: -80,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                AppColors.electricBlue.withOpacity(0.12),
                AppColors.electricBlue.withOpacity(0.06),
                AppColors.electricBlue.withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        top: 500,
        right: 60,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.7,
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                AppColors.primaryColor.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    ];
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

  void _navigateToServicesScreen(
      BuildContext context, ServiceProviderModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderServicesScreen(provider: provider),
      ),
    );
  }

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

  Widget _buildProfessionalLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.deepSpaceNavy),
        child: Stack(
          children: [
            ..._buildAmbientDesign(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.3),
                          AppColors.tealColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    "Loading provider details...",
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalErrorState(String message, VoidCallback onRetry) {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.deepSpaceNavy),
        child: Stack(
          children: [
            ..._buildAmbientDesign(),
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.redColor.withOpacity(0.3),
                            AppColors.redColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: AppColors.redColor,
                        size: 32,
                      ),
                    ),
                    const Gap(24),
                    Text(
                      "Something went wrong",
                      style: AppTextStyle.getHeadlineTextStyle(
                        color: AppColors.lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      message,
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.primaryTextSubtle,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryColor, AppColors.tealColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onRetry,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              "Try Again",
                              style: AppTextStyle.getButtonStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

// Modern Floating CTA Widget
class ModernFloatingCTA extends StatelessWidget {
  final ServiceProviderModel provider;
  final VoidCallback onTap;

  const ModernFloatingCTA({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.6),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.tealColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
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
              AppColors.primaryColor.withOpacity(0.9),
              AppColors.tealColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _getProviderIcon(),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const Gap(20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getButtonText(),
                              style: AppTextStyle.getButtonStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getSubtitleText(),
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getProviderIcon() {
    switch (provider.pricingModel) {
      case PricingModel.reservation:
        return CupertinoIcons.calendar_badge_plus;
      case PricingModel.subscription:
        return CupertinoIcons.creditcard_fill;
      case PricingModel.hybrid:
        return CupertinoIcons.star_circle_fill;
      default:
        return CupertinoIcons.info_circle_fill;
    }
  }

  String _getButtonText() {
    switch (provider.pricingModel) {
      case PricingModel.reservation:
        return "Book Service";
      case PricingModel.subscription:
        return "View Plans";
      case PricingModel.hybrid:
        return "Book or Subscribe";
      default:
        return "Contact Provider";
    }
  }

  String _getSubtitleText() {
    switch (provider.pricingModel) {
      case PricingModel.reservation:
        return "Choose date & time";
      case PricingModel.subscription:
        return "Monthly plans available";
      case PricingModel.hybrid:
        return "Flexible options";
      default:
        return "Get in touch";
    }
  }
}

// Screen Data Model
class ScreenData {
  final ServiceProviderDisplayModel displayData;
  final ServiceProviderModel? detailedProvider;
  final bool isLoading;
  final bool isFavorite;
  final List<String> headerImages;

  ScreenData({
    required this.displayData,
    required this.detailedProvider,
    required this.isLoading,
    required this.isFavorite,
    required this.headerImages,
  });
}

// Helper Extension
extension ServiceProviderModelDetailBooking on ServiceProviderModel {
  bool get canBookOrSubscribeOnlineInDetail =>
      pricingModel != PricingModel.other &&
      (hasReservationsEnabledInDetail || hasSubscriptionsEnabledInDetail);

  bool get hasReservationsEnabledInDetail =>
      (pricingModel == PricingModel.reservation ||
          pricingModel == PricingModel.hybrid) &&
      (bookableServices.isNotEmpty || supportedReservationTypes.isNotEmpty);

  bool get hasSubscriptionsEnabledInDetail =>
      (pricingModel == PricingModel.subscription ||
          pricingModel == PricingModel.hybrid) &&
      subscriptionPlans.isNotEmpty;

  String get getBookingButtonTextInDetail {
    if (pricingModel == PricingModel.reservation) return "Book / View Options";
    if (pricingModel == PricingModel.subscription) {
      return "View Subscription Plans";
    }
    if (pricingModel == PricingModel.hybrid) return "Book or Subscribe";
    return "Contact Provider";
  }
}
