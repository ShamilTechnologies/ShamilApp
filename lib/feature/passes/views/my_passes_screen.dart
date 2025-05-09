 // lib/feature/passes/views/my_passes_screen.dart

 import 'dart:math'; // For ticket cutout effect
 import 'package:flutter/material.dart';
 import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:gap/gap.dart'; // For spacing
 import 'package:intl/intl.dart'; // For date/time formatting
 import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors
 import 'package:cached_network_image/cached_network_image.dart'; // For images
 import 'package:shimmer/shimmer.dart'; // For image placeholder

 // Import Bloc, State, Event
 import 'package:shamil_mobile_app/feature/passes/bloc/my_passes_bloc.dart';

 // Import Models to display
 import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
 import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
 // Import Provider Model for potential future use (fetching details)
 // import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
 // Import placeholder image data
 import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // Contains transparentImageData

 // Enum to differentiate pass types for styling
 enum PassType { upcoming, past, cancelled, active, expired }

 class MyPassesScreen extends StatefulWidget {
   const MyPassesScreen({super.key});

   @override
   State<MyPassesScreen> createState() => _MyPassesScreenState();
 }

 class _MyPassesScreenState extends State<MyPassesScreen>
     with SingleTickerProviderStateMixin {
   late TabController _tabController;

   // Define the tabs
   final List<Tab> _tabs = const [
     Tab(text: 'Upcoming'), // Reservations
     Tab(text: 'Past'),      // Reservations
     Tab(text: 'Cancelled'), // Reservations
     Tab(text: 'Active'),    // Subscriptions
     Tab(text: 'Expired'),   // Subscriptions
   ];

   @override
   void initState() {
     super.initState();
     _tabController = TabController(length: _tabs.length, vsync: this);
     // Load data when the screen initializes
     try {
       context.read<MyPassesBloc>().add(const LoadMyPasses());
     } catch (e) {
       print("Error dispatching LoadMyPasses in initState: $e");
       // Optionally show error via snackbar if Bloc is missing
     }
   }

   @override
   void dispose() {
     _tabController.dispose();
     super.dispose();
   }

   // Helper to build the content list for each tab
   Widget _buildPassList(BuildContext context, ThemeData theme, List<dynamic> items, String emptyMessage, PassType passType) {
     if (items.isEmpty) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(32.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon( // Icon relevant to the tab type
                 passType == PassType.upcoming ? Icons.event_available_outlined : // Changed icon
                 passType == PassType.past ? Icons.history_toggle_off_outlined : // Changed icon
                 passType == PassType.cancelled ? Icons.event_busy_outlined : // Changed icon
                 passType == PassType.active ? Icons.subscriptions_outlined : // Changed icon
                 Icons.unsubscribe_outlined, // Changed icon
                 size: 60,
                 color: Colors.grey.shade400,
               ),
               const Gap(16),
               Text(
                 emptyMessage,
                 textAlign: TextAlign.center,
                 style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
               ),
             ],
           ),
         ),
       );
     }

     // Add RefreshIndicator here for pull-to-refresh within the list view
     return RefreshIndicator(
       onRefresh: () async {
         context.read<MyPassesBloc>().add(const LoadMyPasses());
         await context.read<MyPassesBloc>().stream.firstWhere(
             (s) => s is MyPassesLoaded || s is MyPassesError);
       },
       color: AppColors.primaryColor,
       child: ListView.builder(
         padding: const EdgeInsets.all(12.0), // Padding around the list
         itemCount: items.length,
         itemBuilder: (context, index) {
           final item = items[index];
           // Add some vertical spacing between cards
           return Padding(
             padding: const EdgeInsets.only(bottom: 12.0),
             child: (item is ReservationModel)
                 ? ReservationTicketCard(reservation: item, passType: passType)
                 : (item is SubscriptionModel)
                     ? SubscriptionInfoCard(subscription: item, passType: passType)
                     : const SizedBox.shrink(),
           );
         },
       ),
     );
   }


   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     return Scaffold(
       appBar: AppBar(
         title: const Text('My Passes'),
         elevation: 1.0, // Subtle elevation
         shadowColor: Colors.black.withOpacity(0.1),
         bottom: TabBar(
           controller: _tabController,
           tabs: _tabs,
           isScrollable: true,
           labelColor: theme.colorScheme.primary,
           unselectedLabelColor: Colors.grey.shade600,
           indicatorColor: theme.colorScheme.primary,
           indicatorWeight: 3.0, // Slightly thicker indicator
           labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
           tabAlignment: TabAlignment.start,
           dividerColor: Colors.grey.shade300, // Add subtle divider
         ),
       ),
       body: BlocBuilder<MyPassesBloc, MyPassesState>(
         builder: (context, state) {
           if (state is MyPassesLoading) {
             return const Center(child: CircularProgressIndicator());
           } else if (state is MyPassesError) {
             return Center( // Error display
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.cloud_off_outlined, color: Colors.grey.shade400, size: 50), // Network error icon
                     const Gap(16),
                     Text("Failed to Load Passes", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                     const Gap(8),
                     Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                     const Gap(24),
                     ElevatedButton.icon( // Added icon to button
                       icon: const Icon(Icons.refresh_rounded, size: 18),
                       label: const Text('Retry'),
                       onPressed: () => context.read<MyPassesBloc>().add(const LoadMyPasses()),
                     )
                   ],
                 ),
               ),
             );
           } else if (state is MyPassesLoaded) {
             // TabBarView now contains the RefreshIndicator via _buildPassList
             return TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Reservations
                  _buildPassList(context, theme, state.upcomingReservations, "You have no upcoming reservations.", PassType.upcoming),
                  // Past Reservations
                  _buildPassList(context, theme, state.pastReservations, "No reservations in your history.", PassType.past),
                  // Cancelled Reservations
                  _buildPassList(context, theme, state.cancelledReservations, "No cancelled reservations found.", PassType.cancelled),
                  // Active Subscriptions
                  _buildPassList(context, theme, state.activeSubscriptions, "You have no active subscriptions.", PassType.active),
                  // Expired/Stopped Subscriptions
                  _buildPassList(context, theme, state.expiredSubscriptions, "No expired or stopped subscriptions.", PassType.expired),
                ],
              );
           } else {
             // Initial state
             return const Center(child: CircularProgressIndicator());
           }
         },
       ),
     );
   }
 }


 // ==========================================================
 // Reservation Ticket Card Widget (Refactored)
 // ==========================================================
 class ReservationTicketCard extends StatelessWidget {
   final ReservationModel reservation;
   final PassType passType;

   const ReservationTicketCard({
     super.key,
     required this.reservation,
     required this.passType,
   });

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final bool isCancelled = passType == PassType.cancelled;
     final bool isPast = passType == PassType.past;
     final bool isUpcoming = passType == PassType.upcoming;

     // Determine colors based on type
     final Color cardBgColor = isPast || isCancelled ? Colors.grey.shade100 : Colors.white;
     final Color contentColor = isPast || isCancelled ? Colors.grey.shade600 : theme.colorScheme.onSurface;
     final Color secondaryColor = isPast || isCancelled ? Colors.grey.shade500 : Colors.grey.shade600;
     final Color iconColor = isPast || isCancelled ? Colors.grey.shade500 : theme.colorScheme.primary;
     final Color accentColor = isCancelled ? theme.colorScheme.error : (isPast ? Colors.grey.shade400 : theme.colorScheme.primary);

     // Format date and time
     String dateString = 'N/A';
     String timeString = 'N/A';
     if (reservation.reservationStartTime != null) {
       final localTime = reservation.reservationStartTime!.toDate().toLocal();
       dateString = DateFormat('EEE, MMM d').format(localTime); // Date only
       timeString = DateFormat('hh:mm a').format(localTime); // Time only
     }

     // Placeholder for Provider Name/Image
     String providerName = "Provider ID: ${reservation.providerId.substring(0, min(6, reservation.providerId.length))}..."; // Safer substring
     String? providerImageUrl; // TODO: Fetch or use denormalized data

     return Opacity(
       opacity: isUpcoming ? 1.0 : 0.7, // Dim past/cancelled
       child: Material( // Use Material for InkWell and custom shape if needed
         color: cardBgColor,
         elevation: isUpcoming ? 2.0 : 0.5,
         shadowColor: Colors.black.withOpacity(0.1),
         borderRadius: BorderRadius.circular(12.0), // Outer radius
         child: InkWell(
           borderRadius: BorderRadius.circular(12.0),
           onTap: () {
             print("Tapped reservation ticket: ${reservation.id}");
             // TODO: Navigate to Reservation Details
           },
           child: ClipPath( // Use ClipPath for the ticket cutout effect
             clipper: TicketClipper(holeRadius: 10.0, bottom: 65.0), // Adjust bottom position
             child: Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(12.0),
                 border: Border(
                   left: BorderSide(color: accentColor, width: 5.0), // Colored side border
                   top: BorderSide(color: Colors.grey.shade200, width: 0.5),
                   right: BorderSide(color: Colors.grey.shade200, width: 0.5),
                   bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                 ),
               ),
               child: IntrinsicHeight( // Ensure Row takes height of its children
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     // Left Side (Date/Time)
                     Container(
                       width: 80, // Fixed width for date/time section
                       padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                       decoration: BoxDecoration(
                         // Optional: Slightly different background for date section
                         // color: accentColor.withOpacity(0.05),
                         border: Border(
                           right: BorderSide(color: Colors.grey.shade200, width: 1.0), // Separator line
                         ),
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             DateFormat('MMM').format(reservation.reservationStartTime?.toDate().toLocal() ?? DateTime.now()).toUpperCase(), // Month Abbreviation
                             style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor, fontWeight: FontWeight.w600),
                           ),
                           Text(
                             DateFormat('dd').format(reservation.reservationStartTime?.toDate().toLocal() ?? DateTime.now()), // Day
                             style: theme.textTheme.titleLarge?.copyWith(color: contentColor, fontWeight: FontWeight.bold),
                           ),
                           const Gap(4),
                            Text(
                             DateFormat('EEE').format(reservation.reservationStartTime?.toDate().toLocal() ?? DateTime.now()), // Day Name
                             style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
                           ),
                           const Spacer(), // Pushes time to bottom
                            Text(
                             timeString,
                             style: theme.textTheme.bodyMedium?.copyWith(color: contentColor, fontWeight: FontWeight.w500),
                           ),
                         ],
                       ),
                     ),

                     // Right Side (Details)
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                         child: Stack( // Stack for Cancelled overlay
                           children: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text( // Provider Name
                                   providerName,
                                   style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
                                   maxLines: 1, overflow: TextOverflow.ellipsis,
                                 ),
                                 const Gap(4),
                                 Text( // Service Name or Type
                                   reservation.serviceName ?? reservation.type.displayString,
                                   style: theme.textTheme.titleMedium?.copyWith(color: contentColor, fontWeight: FontWeight.w600),
                                   maxLines: 2, overflow: TextOverflow.ellipsis,
                                 ),
                                 const Spacer(), // Pushes bottom info down
                                 Row( // Attendees and Status Icon
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   crossAxisAlignment: CrossAxisAlignment.end,
                                   children: [
                                     if (reservation.attendees.length > 1)
                                       Row(
                                         children: [
                                           Icon(Icons.group_outlined, size: 16, color: secondaryColor),
                                           const Gap(4),
                                           Text(
                                             "${reservation.attendees.length} Attendees",
                                             style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
                                           ),
                                         ],
                                       )
                                     else const SizedBox(), // Placeholder if only 1 attendee
                                     // Status Icon
                                     if (isUpcoming && reservation.status == ReservationStatus.confirmed)
                                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 22)
                                     else if (isUpcoming && reservation.status == ReservationStatus.pending)
                                        Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 20)
                                     else if (isPast && reservation.status == ReservationStatus.completed)
                                        Icon(Icons.task_alt_rounded, color: Colors.grey.shade500, size: 20)
                                     else if (isPast && reservation.status == ReservationStatus.noShow)
                                        Icon(Icons.person_off_outlined, color: Colors.grey.shade500, size: 20)
                                     // Cancelled status is handled by the overlay
                                   ],
                                 )
                               ],
                             ),
                             // Cancelled Stamp Overlay
                             if (isCancelled)
                               Positioned.fill(
                                 child: Container(
                                   color: Colors.black.withOpacity(0.0), // Transparent bg
                                   child: Center(
                                     child: Transform.rotate(
                                       angle: -pi / 6, // Angle the stamp
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                         decoration: BoxDecoration(
                                           border: Border.all(color: theme.colorScheme.error.withOpacity(0.7), width: 2),
                                           borderRadius: BorderRadius.circular(4),
                                         ),
                                         child: Text(
                                           "CANCELLED",
                                           style: TextStyle(
                                             fontSize: 14,
                                             fontWeight: FontWeight.bold,
                                             color: theme.colorScheme.error.withOpacity(0.7),
                                             letterSpacing: 1.5,
                                           ),
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
             ),
           ),
         ),
       ),
     );
   }

   // Helper for image placeholder
   Widget _buildImagePlaceholder(double size) {
     return Shimmer.fromColors(
       baseColor: Colors.grey.shade300,
       highlightColor: Colors.grey.shade100,
       child: Container(width: size, height: size, color: Colors.white),
     );
   }

   // Helper for image error/fallback
   Widget _buildImageErrorWidget(double size, Color color) {
     return Container(
       width: size, height: size,
       color: color.withOpacity(0.1),
       child: Icon(Icons.business_rounded, color: color.withOpacity(0.5), size: size * 0.6),
     );
   }
 }

 // ==========================================================
 // Subscription Info Card Widget (Refactored)
 // ==========================================================
 class SubscriptionInfoCard extends StatelessWidget {
   final SubscriptionModel subscription;
   final PassType passType;

   const SubscriptionInfoCard({
     super.key,
     required this.subscription,
     required this.passType,
   });

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final bool isActive = passType == PassType.active;
     final bool isExpiredOrStopped = passType == PassType.expired;

     // Determine colors based on type
     final Color cardColor = isExpiredOrStopped ? Colors.grey.shade100 : Colors.white;
     final Color primaryTextColor = isExpiredOrStopped ? Colors.grey.shade700 : theme.colorScheme.onSurface;
     final Color secondaryTextColor = isExpiredOrStopped ? Colors.grey.shade500 : Colors.grey.shade600;
     final Color accentColor = isActive ? AppColors.primaryColor : Colors.grey.shade400;

     // Format dates
     final expiryDateString = DateFormat('MMM d, yyyy').format(subscription.expiryDate.toDate().toLocal());
     final startDateString = DateFormat('MMM d, yyyy').format(subscription.startDate.toDate().toLocal());

     // Placeholder for Provider Name
     String providerName = "Provider ID: ${subscription.providerId.substring(0, min(6, subscription.providerId.length))}..."; // TODO: Fetch name

     return Opacity(
       opacity: isActive ? 1.0 : 0.7,
       child: Card(
         margin: EdgeInsets.zero, // Removed default card margin
         elevation: isActive ? 2.5 : 0.5,
         shadowColor: Colors.black.withOpacity(0.1),
         color: cardColor,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10.0),
           side: BorderSide(color: accentColor.withOpacity(isActive ? 0.5 : 0.3), width: 1.0),
         ),
         child: InkWell(
           borderRadius: BorderRadius.circular(10.0),
           onTap: () {
             print("Tapped subscription card: ${subscription.id}");
             // TODO: Navigate to Subscription Details
           },
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Icon indicating subscription
                     Icon(Icons.card_membership_rounded, color: accentColor, size: 28),
                     const Gap(12),
                     // Plan Name and Provider
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             subscription.planName,
                             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primaryTextColor),
                             maxLines: 1, overflow: TextOverflow.ellipsis,
                           ),
                           const Gap(2),
                           Text(
                             providerName,
                             style: theme.textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                           ),
                         ],
                       ),
                     ),
                     const Gap(8),
                      // Status Chip
                     Chip(
                       label: Text(
                         isActive ? "Active" : subscription.status.toString().split('.').last,
                         style: theme.textTheme.labelSmall?.copyWith(
                           color: isActive ? Colors.green.shade900 : Colors.orange.shade900,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       backgroundColor: isActive ? Colors.green.shade100.withOpacity(0.8) : Colors.orange.shade100.withOpacity(0.8),
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       visualDensity: VisualDensity.compact,
                       side: BorderSide.none,
                     )
                   ],
                 ),
                 const Gap(12),
                 Divider(color: Colors.grey.shade300, height: 1),
                 const Gap(12),
                 // Dates Row
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     _buildDateInfo(theme, "Start Date", startDateString, secondaryTextColor),
                     _buildDateInfo(theme, "Expiry Date", expiryDateString, secondaryTextColor),
                   ],
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }

   // Helper for date info in the subscription card
   Widget _buildDateInfo(ThemeData theme, String label, String date, Color textColor) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: theme.textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8))),
         const Gap(2),
         Text(date, style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500)),
       ],
     );
   }
 }

 // ==========================================================
 // Ticket Clipper for Reservation Card
 // ==========================================================
 class TicketClipper extends CustomClipper<Path> {
   final double holeRadius;
   final double bottom; // Position of the cutout line from the top

   TicketClipper({required this.holeRadius, required this.bottom});

   @override
   Path getClip(Size size) {
     final path = Path()
       ..moveTo(0, 0)
       ..lineTo(size.width, 0)
       ..lineTo(size.width, size.height)
       ..lineTo(0, size.height)
       ..lineTo(0, 0); // Close the outer rectangle path

     // Create the circular cutout path
     final holePath = Path()
       ..addOval(Rect.fromCircle(center: Offset(0, bottom), radius: holeRadius)) // Left hole
       ..addOval(Rect.fromCircle(center: Offset(size.width, bottom), radius: holeRadius)); // Right hole

     // Combine the paths using difference
     return Path.combine(PathOperation.difference, path, holePath);
   }

   @override
   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true; // Reclip if properties change
 }
 