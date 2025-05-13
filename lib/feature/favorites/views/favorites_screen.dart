import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: AppColors.primaryColor,
                  size: 48,
                ),
              ),
              const Gap(16),
              Text(
                'Sign In Required',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                'Please sign in to view your favorites',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const _FavoritesView();
  }
}

class _FavoritesView extends StatefulWidget {
  const _FavoritesView();

  @override
  State<_FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<_FavoritesView> {
  @override
  void initState() {
    super.initState();
    // Force refresh favorites on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const LoadFavorites());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<FavoritesBloc>()
                            .add(const LoadFavorites());
                        return await Future.delayed(const Duration(seconds: 1));
                      },
                      child: _buildFavoritesContent(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Gap(14),
                  Text(
                    'Favorites',
                    style: AppTextStyle.getHeadlineTextStyle(
                      color: AppColors.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildRefreshButton(context),
            ],
          ),
          const Gap(12),
          Text(
            'Service providers you have saved',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<FavoritesBloc>().add(const LoadFavorites());
        showGlobalSnackBar(context, "Refreshing favorites...");
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.arrow_clockwise,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFavoritesContent() {
    return BlocConsumer<FavoritesBloc, FavoritesState>(
      listener: (context, state) {
        if (state is FavoritesError) {
          showGlobalSnackBar(
            context,
            "Error loading favorites: ${state.message}",
            isError: true,
          );
        } else if (state is FavoritesLoaded) {
          // Only show success message when refreshing, not on initial load
          ScaffoldMessenger.of(context).clearSnackBars();
          // Check if we're refreshing (not the initial load)
          if (mounted && state.operationInProgressId != null) {
            showGlobalSnackBar(context, "Favorites updated successfully");
          }
        }
      },
      builder: (context, state) {
        if (state is FavoritesInitial || state is FavoritesLoading) {
          return _buildLoadingShimmer();
        } else if (state is FavoritesError) {
          return _buildErrorState(context, state.message);
        } else if (state is FavoritesLoaded) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
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
                        child: _FavoriteCard(
                          provider: provider,
                          onRemove: () {
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
          );
        }

        return Center(
          child: Text(
            'Something went wrong',
            style: AppTextStyle.getbodyStyle(),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.heart,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(16),
          Text(
            'No Favorites Yet',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Save service providers to your favorites to see them here',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.red,
              size: 48,
            ),
          ),
          const Gap(16),
          Text(
            'Error Loading Favorites',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<FavoritesBloc>().add(const LoadFavorites());
            },
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.provider,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            InkWell(
              onTap: () {
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
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: CachedNetworkImage(
                          imageUrl: provider.imageUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const Gap(8),
                                Text(
                                  'No Image',
                                  style: AppTextStyle.getSmallStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (provider.businessCategory.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              provider.businessCategory,
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.businessName,
                          style: AppTextStyle.getTitleStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const Gap(2),
                            Expanded(
                              child: Text(
                                provider.city.isNotEmpty
                                    ? provider.city
                                    : 'Location unavailable',
                                style: AppTextStyle.getSmallStyle(
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[700]!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.star_fill,
                                    size: 12,
                                    color: Colors.amber[700],
                                  ),
                                  const Gap(3),
                                  Text(
                                    provider.averageRating.toStringAsFixed(1),
                                    style: AppTextStyle.getSmallStyle(
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(4),
                            Text(
                              '(${provider.ratingCount})',
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.heart_fill,
                    size: 20,
                    color: Colors.red[400],
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
