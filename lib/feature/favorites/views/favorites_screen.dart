import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F23),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F0F23),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.3),
                              AppColors.accentColor.withOpacity(0.3),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const Gap(24),
                      Text(
                        'Sign In Required',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Please sign in to view your favorites',
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const _PremiumFavoritesView();
  }
}

class _PremiumFavoritesView extends StatefulWidget {
  const _PremiumFavoritesView();

  @override
  State<_PremiumFavoritesView> createState() => _PremiumFavoritesViewState();
}

class _PremiumFavoritesViewState extends State<_PremiumFavoritesView>
    with TickerProviderStateMixin {
  // Premium animation controllers
  late final AnimationController _animationController;
  late final AnimationController _orbAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup premium animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _orbAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // Force refresh favorites on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const LoadFavorites());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _orbAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated floating orbs
            ..._buildFloatingOrbs(),

            // Main content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Pull to refresh indicator
                CupertinoSliverRefreshControl(
                  builder: (context, refreshState, pulledExtent,
                      refreshTriggerPullDistance, refreshIndicatorExtent) {
                    return Container(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor.withOpacity(0.8),
                                AppColors.tealColor.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: refreshState == RefreshIndicatorMode.refresh
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    );
                  },
                  onRefresh: () async {
                    context.read<FavoritesBloc>().add(const LoadFavorites());
                    return Future.delayed(const Duration(seconds: 1));
                  },
                ),

                // Premium header
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 140,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding:
                          const EdgeInsets.only(left: 20, right: 20, top: 80),
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Premium badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.8),
                                          Colors.pink.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const Gap(3),
                                        Text(
                                          'SAVED COLLECTION',
                                          style: AppTextStyle.getbodyStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(8),

                                  // Title with gradient text
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [Colors.white, Color(0xFFB8BCC8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      'Favorites',
                                      style: AppTextStyle.getTitleStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Content with premium styling
                SliverFillRemaining(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xFF0A0A1A),
                        ],
                      ),
                    ),
                    child: _buildPremiumFavoritesContent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs() {
    return [
      // Large orb top right
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            top: 100 + (20 * (_orbAnimationController.value * 2 - 1).abs()),
            right: 50 + (15 * (_orbAnimationController.value * 2 - 1)),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(0.3),
                    Colors.red.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Medium orb middle left
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            top: 300 + (30 * _orbAnimationController.value),
            left: 30 + (20 * (1 - _orbAnimationController.value)),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.pink.withOpacity(0.4),
                    Colors.pink.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Small orb bottom right
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            bottom: 200 + (25 * _orbAnimationController.value),
            right: 80 + (10 * (_orbAnimationController.value * 2 - 1)),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.3),
                    AppColors.primaryColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildPremiumFavoritesContent() {
    return BlocConsumer<FavoritesBloc, FavoritesState>(
      listener: (context, state) {
        if (state is FavoritesError) {
          showGlobalSnackBar(
            context,
            "Error loading favorites: ${state.message}",
            isError: true,
          );
        } else if (state is FavoritesLoaded &&
            state.operationInProgressId != null) {
          showGlobalSnackBar(context, "Favorites updated successfully");
        }
      },
      builder: (context, state) {
        if (state is FavoritesInitial || state is FavoritesLoading) {
          return _buildPremiumLoadingShimmer();
        } else if (state is FavoritesError) {
          return _buildPremiumErrorState(context, state.message);
        } else if (state is FavoritesLoaded) {
          if (state.favorites.isEmpty) {
            return _buildPremiumEmptyState(context);
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AnimationLimiter(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: state.favorites.length,
                        itemBuilder: (context, index) {
                          final provider = state.favorites[index];
                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            columnCount:
                                MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: _PremiumFavoriteCard(
                                  provider: provider,
                                  onRemove: () {
                                    HapticFeedback.lightImpact();
                                    context
                                        .read<FavoritesBloc>()
                                        .add(ToggleFavorite(provider));
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Center(
          child: Text(
            'Something went wrong',
            style: AppTextStyle.getbodyStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildPremiumLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.pink.withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.heart,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const Gap(24),
                Text(
                  'No Favorites Yet',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(16),
                Text(
                  'Save service providers to your favorites to see them here',
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumErrorState(BuildContext context, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.15),
              Colors.red.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white,
                  size: 48,
                ),
                const Gap(20),
                Text(
                  'Error Loading Favorites',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(12),
                Text(
                  message,
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                Material(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<FavoritesBloc>().add(const LoadFavorites());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.8),
                            Colors.red.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.refresh,
                              color: Colors.white),
                          const Gap(8),
                          Text(
                            'Try Again',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class _PremiumFavoriteCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;
  final VoidCallback onRemove;

  const _PremiumFavoriteCard({
    required this.provider,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: BlocProvider.of<FavoritesBloc>(context),
                          child: ServiceProviderDetailScreen(
                            providerId: provider.id,
                            heroTag: 'favorites_${provider.id}',
                            initialProviderData: provider,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with gradient overlay
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                image: provider.imageUrl?.isNotEmpty == true
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            provider.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: provider.imageUrl?.isEmpty != false
                                    ? Colors.white.withOpacity(0.1)
                                    : null,
                              ),
                              child: provider.imageUrl?.isEmpty != false
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.photo,
                                          size: 40,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const Gap(8),
                                        Text(
                                          'No Image',
                                          style: AppTextStyle.getSmallStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),

                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),

                            // Category badge
                            if (provider.businessCategory.isNotEmpty)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.9),
                                        AppColors.accentColor.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    provider.businessCategory,
                                    style: AppTextStyle.getSmallStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Content section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.businessName,
                                style: AppTextStyle.getTitleStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const Gap(3),
                                  Expanded(
                                    child: Text(
                                      provider.city.isNotEmpty
                                          ? provider.city
                                          : 'Location unavailable',
                                      style: AppTextStyle.getSmallStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.withOpacity(0.8),
                                          Colors.orange.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.star_fill,
                                          size: 9,
                                          color: Colors.white,
                                        ),
                                        const Gap(2),
                                        Text(
                                          provider.averageRating
                                              .toStringAsFixed(1),
                                          style: AppTextStyle.getSmallStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    '(${provider.ratingCount})',
                                    style: AppTextStyle.getSmallStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Premium favorite button
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.9),
                            Colors.pink.withOpacity(0.9),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        size: 16,
                        color: Colors.white,
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
}

class FavoritesSearchDelegate extends SearchDelegate {
  List<ServiceProviderDisplayModel> _filterFavorites(
      List<ServiceProviderDisplayModel> favorites, String query) {
    if (query.isEmpty) return favorites;
    final lowerQuery = query.toLowerCase();
    return favorites.where((provider) {
      return provider.businessName.toLowerCase().contains(lowerQuery) ||
          provider.shortDescription != null &&
              provider.shortDescription!.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final state = context.watch<FavoritesBloc>().state;
    if (state is FavoritesLoaded) {
      final results = _filterFavorites(state.favorites, query);
      if (results.isEmpty) {
        return const Center(child: Text('No matching favorites found.'));
      }
      return _buildResultsList(context, results);
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final state = context.watch<FavoritesBloc>().state;
    if (state is FavoritesLoaded) {
      final suggestions =
          _filterFavorites(state.favorites, query).take(5).toList();
      return _buildResultsList(context, suggestions);
    }
    return const SizedBox.shrink();
  }

  Widget _buildResultsList(
      BuildContext context, List<ServiceProviderDisplayModel> providers) {
    if (providers.isEmpty) {
      return const Center(child: Text('No results.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final provider = providers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                provider.imageUrl != null && provider.imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(provider.imageUrl!)
                    : null,
            backgroundColor: Colors.grey[300],
            child: provider.imageUrl == null || provider.imageUrl!.isEmpty
                ? const Icon(Icons.image_not_supported)
                : null,
          ),
          title: Text(provider.businessName),
          subtitle: Text(
              provider.shortDescription ?? 'No description available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: BlocProvider.of<FavoritesBloc>(context),
                  child: ServiceProviderDetailScreen(
                    providerId: provider.id,
                    heroTag: 'search_${provider.id}',
                    initialProviderData: provider,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
