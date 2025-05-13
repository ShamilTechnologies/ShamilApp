import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/social/views/add_family_member_view.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/feature/profile/widgets/family_list_tiles.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FamilyView extends StatefulWidget {
  const FamilyView({super.key});

  @override
  State<FamilyView> createState() => _FamilyViewState();
}

class _FamilyViewState extends State<FamilyView> {
  @override
  void initState() {
    super.initState();
    // Load family members when view initializes
    context.read<SocialBloc>().add(const LoadFamilyMembers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SocialBloc, SocialState>(
        listener: (context, state) {
          if (state is SocialSuccess) {
            showGlobalSnackBar(context, state.message);
          } else if (state is SocialError) {
            showGlobalSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          // Show loading state
          if (state is SocialLoading && state.isLoadingList) {
            return _buildLoadingShimmer();
          }

          // Extract family members from state
          List<FamilyMember> familyMembers = [];
          List<FamilyRequest> incomingRequests = [];

          if (state is FamilyDataLoaded) {
            familyMembers = state.familyMembers;
            incomingRequests = state.incomingRequests;
          }

          if (familyMembers.isEmpty && incomingRequests.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Incoming requests section
                      if (incomingRequests.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Incoming Requests',
                          'Respond to family connection requests',
                          CupertinoIcons.person_crop_circle_badge_exclam,
                        ),
                        const Gap(8),
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: incomingRequests
                                  .map((request) => buildFamilyRequestTile(
                                        context,
                                        Theme.of(context),
                                        request,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        const Gap(24),
                      ],

                      // Family members section
                      if (familyMembers.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Family Members',
                          'People connected to your account',
                          CupertinoIcons.person_2_fill,
                        ),
                        const Gap(8),
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: familyMembers
                                  .map((member) => buildFamilyMemberTile(
                                        context,
                                        Theme.of(context),
                                        member,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<SocialBloc>(),
                child: const AddFamilyMemberView(),
              ),
            ),
          ).then((_) {
            // Refresh the list when returning from add screen
            context.read<SocialBloc>().add(const LoadFamilyMembers());
          });
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(CupertinoIcons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
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
                                  Colors.white,
                                  Colors.white.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              CupertinoIcons.person_2_fill,
                              color: AppColors.primaryColor,
                              size: 26,
                            ),
                          ),
                          const Gap(14),
                          Text(
                            'Family Members',
                            style: AppTextStyle.getHeadlineTextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.refresh,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          context
                              .read<SocialBloc>()
                              .add(const LoadFamilyMembers());
                        },
                      ),
                    ],
                  ),
                  const Gap(12),
                  Text(
                    'Manage your family connections and requests',
                    style: AppTextStyle.getbodyStyle(
                      color: Colors.white.withOpacity(0.9),
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

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer for section header
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 16),
                    height: 24,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Shimmer for list items
                  ...List.generate(
                    4,
                    (index) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                CupertinoIcons.person_2,
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            const Gap(16),
            Text(
              'No Family Members Yet',
              style: AppTextStyle.getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Add your family members to connect your accounts and manage reservations together.',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<SocialBloc>(),
                      child: const AddFamilyMemberView(),
                    ),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.person_add),
              label: const Text('Add Family Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
