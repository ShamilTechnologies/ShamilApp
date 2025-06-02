import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_event.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_state.dart';
import 'package:shamil_mobile_app/feature/community/models/tournament_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;

class TournamentsTab extends StatefulWidget {
  const TournamentsTab({super.key});

  @override
  State<TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<TournamentsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    context.read<CommunityBloc>().add(const LoadTournamentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: () async {
        _loadTournaments();
      },
      child: BlocBuilder<CommunityBloc, CommunityState>(
        buildWhen: (previous, current) {
          if (previous is CommunityLoaded && current is CommunityLoaded) {
            return previous.tournaments != current.tournaments;
          }
          return previous != current;
        },
        builder: (context, state) {
          if (state is CommunityLoading) {
            return _buildLoadingState();
          } else if (state is CommunityLoaded) {
            if (state.tournaments.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTournamentsList(state.tournaments);
          } else if (state is CommunityError) {
            return _buildErrorState(state.message);
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tournaments Available',
            style: AppTextStyle.getHeadlineTextStyle(
              color: Colors.grey[800],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no tournaments scheduled.\nCheck back later for upcoming tournaments.',
            textAlign: TextAlign.center,
            style: AppTextStyle.getbodyStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTournaments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 72,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: AppTextStyle.getHeadlineTextStyle(
              color: Colors.grey[800],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: AppTextStyle.getbodyStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTournaments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsList(List<TournamentModel> tournaments) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return _buildTournamentCard(tournament);
      },
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final startDate = dateFormat.format(tournament.startDate);
    final endDate = dateFormat.format(tournament.endDate);

    final statusColor = _getStatusColor(tournament.status);
    final statusText = _getStatusText(tournament.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTournamentTap(tournament),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament image with status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    tournament.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.emoji_events,
                            size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tournament details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title,
                    style: AppTextStyle.getHeadlineTextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Game type and tournament type
                  Row(
                    children: [
                      Icon(Icons.sports_esports,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        tournament.gameType,
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        tournament.tournamentType == 'team'
                            ? Icons.group
                            : Icons.person,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tournament.tournamentType == 'team'
                            ? 'Team'
                            : 'Individual',
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date and location
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '$startDate - $endDate',
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        tournament.location,
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Participants and prizes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people,
                              size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${tournament.participantsCount}/${tournament.maxParticipants} participants',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.monetization_on,
                              size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            tournament.prizes.isNotEmpty
                                ? '${tournament.prizes.first.amount} ${tournament.currency}'
                                : 'No prize',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Join button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: tournament.status == 'registration' ||
                              tournament.status == 'upcoming'
                          ? () => _onJoinTournament(tournament)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _getButtonText(tournament),
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _onTournamentTap(TournamentModel tournament) {
    context.read<CommunityBloc>().add(SelectTournamentEvent(tournament));
    // Navigate to tournament details page
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => TournamentDetailsScreen(tournamentId: tournament.id),
    // ));
  }

  void _onJoinTournament(TournamentModel tournament) {
    final currentUser = context.read<CommunityBloc>();
    // In a real app, you would get these values from user repository or auth service
    final userId = "current_user_id"; // Replace with actual user ID
    final userName = "Current User"; // Replace with actual user name

    context.read<CommunityBloc>().add(JoinTournamentEvent(
          tournamentId: tournament.id,
          userId: userId,
          userName: userName,
        ));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'registration':
        return Colors.blue;
      case 'upcoming':
        return Colors.orange;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'registration':
        return 'Registration Open';
      case 'upcoming':
        return 'Upcoming';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getButtonText(TournamentModel tournament) {
    // In a real app, you would get the current user ID from a repository or auth service
    const currentUserId = "current_user_id"; // Replace with actual user ID
    final isParticipant = tournament.participantIds.contains(currentUserId);

    switch (tournament.status) {
      case 'registration':
        return isParticipant ? 'Registered' : 'Register Now';
      case 'upcoming':
        return isParticipant ? 'View Details' : 'Join Tournament';
      case 'ongoing':
        return 'View Matches';
      case 'completed':
        return 'View Results';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'View Details';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
