import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Alias to avoid conflicts
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view favorites'),
        ),
      );
    }

    return const _FavoritesView();
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FavoritesBloc>();
      if (bloc.state is FavoritesInitial ||
          fb_auth.FirebaseAuth.instance.currentUser?.uid != null) {
        print('_FavoritesView: Requesting LoadFavorites.');
        bloc.add(const LoadFavorites());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Manually refreshing favorites from FavoritesScreen');
              context.read<FavoritesBloc>().add(const LoadFavorites());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FavoritesSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('Pull-to-refresh triggered');
          context.read<FavoritesBloc>().add(const LoadFavorites());
          // Wait for the state to change
          return await Future.delayed(const Duration(seconds: 1));
        },
        child: BlocConsumer<FavoritesBloc, FavoritesState>(
          listener: (context, state) {
            if (state is FavoritesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<FavoritesBloc>().add(const LoadFavorites());
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            print('FavoritesScreen _FavoritesView current state: $state');

            Widget content;

            if (state is FavoritesInitial || state is FavoritesLoading) {
              content = const Center(child: CircularProgressIndicator());
            } else if (state is FavoritesError) {
              content = Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading favorites',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<FavoritesBloc>()
                            .add(const LoadFavorites());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (state is FavoritesLoaded) {
              if (state.favorites.isEmpty) {
                content = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add service providers to your favorites to see them here',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                content = AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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
                                context.read<FavoritesBloc>().add(
                                      RemoveFromFavorites(provider.id),
                                    );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            } else {
              content = const Center(
                child: Text('Something went wrong or unhandled state'),
              );
            }

            return content is GridView
                ? content
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      alignment: Alignment.center,
                      height: MediaQuery.of(context).size.height -
                          AppBar().preferredSize.height -
                          MediaQuery.of(context).padding.top,
                      child: content,
                    ),
                  );
          },
        ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: provider.imageUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.businessName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.shortDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${provider.ratingCount})',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
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
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.favorite,
                    size: 20,
                    color: Colors.red[400],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          provider.shortDescription.toLowerCase().contains(lowerQuery);
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
          subtitle: Text(provider.shortDescription,
              maxLines: 1, overflow: TextOverflow.ellipsis),
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
