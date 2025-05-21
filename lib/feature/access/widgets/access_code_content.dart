// lib/feature/access/widgets/access_code_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:gap/gap.dart';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import shared constants/helpers
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'
    as app_placeholders;
import 'package:shamil_mobile_app/feature/access/bloc/access_bloc.dart';
import 'package:shamil_mobile_app/feature/access/widgets/wireless_animation.dart';
import 'package:shamil_mobile_app/feature/passes/view/passes_screen.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/queue_reservation_page.dart';

class AccessCodeContent extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? profileImageUrl;
  final bool isBottomSheet;

  const AccessCodeContent({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileImageUrl,
    this.isBottomSheet = false,
  });

  @override
  State<AccessCodeContent> createState() => _AccessCodeContentState();
}

class _AccessCodeContentState extends State<AccessCodeContent>
    with TickerProviderStateMixin {
  late AnimationController _entryAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;
  bool _nfcAvailable = false;
  bool _nfcScanning = false;
  bool _nfcActive = false;

  @override
  void initState() {
    super.initState();
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeInOut,
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
        parent: _pulseAnimationController, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entryAnimationController.forward();
        _pulseAnimationController.repeat(reverse: true);
      }
    });

    // Check NFC availability when widget is initialized
    // and automatically activate it
    _checkNFCAvailability();
    _activateNFC();
  }

  void _checkNFCAvailability() {
    if (context.mounted) {
      context.read<AccessBloc>().add(CheckNFCAvailabilityEvent());
    }
  }

  void _activateNFC() {
    if (context.mounted && widget.userId != null && widget.userId!.isNotEmpty) {
      context.read<AccessBloc>().add(ActivateNFCEvent());
      setState(() {
        _nfcActive = true;
      });
    }
  }

  void _startNFCScanning() {
    if (_nfcAvailable && !_nfcScanning) {
      context.read<AccessBloc>().add(StartNFCSessionEvent());
      setState(() {
        _nfcScanning = true;
      });
    }
  }

  void _stopNFCScanning() {
    if (_nfcScanning) {
      context.read<AccessBloc>().add(StopNFCSessionEvent());
      setState(() {
        _nfcScanning = false;
      });
    }
  }

  // Start NFC beam to share user ID
  void _startNFCSharing() {
    if (_nfcAvailable && widget.userId != null && widget.userId!.isNotEmpty) {
      context.read<AccessBloc>().add(StartNFCBeamSessionEvent(widget.userId!));
      setState(() {
        _nfcScanning = true;
      });
    }
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _pulseAnimationController.dispose();
    _stopNFCScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = widget.userId ?? "error_user_id_not_found";
    final borderRadius = BorderRadius.circular(8.0);
    const double profilePicSize = 64.0;

    final padding = widget.isBottomSheet
        ? const EdgeInsets.only(
            left: 24.0, right: 24.0, top: 24.0, bottom: 40.0)
        : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0);

    // Ensure profileImageUrl handles empty string
    String? effectiveProfileImageUrl = widget.profileImageUrl;
    if (effectiveProfileImageUrl != null && effectiveProfileImageUrl.isEmpty) {
      effectiveProfileImageUrl = null;
    }

    return BlocListener<AccessBloc, AccessState>(
      listener: (context, state) {
        if (state is NFCAvailableState) {
          setState(() {
            _nfcAvailable = true;
            _nfcScanning = false;
          });

          // If NFC is available and we have a userId, activate NFC sharing
          if (widget.userId != null &&
              widget.userId!.isNotEmpty &&
              !_nfcActive) {
            _activateNFC();
          }
        } else if (state is NFCUnavailableState) {
          setState(() {
            _nfcAvailable = false;
            _nfcScanning = false;
            _nfcActive = false;
          });
        } else if (state is NFCReadingState || state is NFCWritingState) {
          setState(() {
            _nfcScanning = true;
          });
        } else if (state is NFCSuccessState || state is NFCErrorState) {
          setState(() {
            _nfcScanning = false;
          });

          // If we had a successful NFC interaction, restart the NFC sharing after a delay
          if (state is NFCSuccessState && _nfcActive) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _nfcActive) {
                _activateNFC();
              }
            });
          }
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                widget.isBottomSheet ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Profile Picture with Hero ---
              Hero(
                // *** Use UNIQUE Hero Tag ***
                tag:
                    'userProfilePic_hero_access', // Unique tag for access screen
                child: SizedBox(
                  width: profilePicSize,
                  height: profilePicSize,
                  child: Material(
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    clipBehavior: Clip.antiAlias,
                    elevation: 2.0,
                    shadowColor: Colors.black.withOpacity(0.2),
                    child: (effectiveProfileImageUrl == null)
                        ? app_placeholders.buildProfilePlaceholder(
                            name: widget.userName ?? "User",
                            size: profilePicSize,
                            borderRadius: borderRadius,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            textColor: theme.colorScheme.primary,
                            defaultIcon: Icons.person_rounded,
                          )
                        : FadeInImage.memoryNetwork(
                            placeholder: transparentImageData,
                            image: effectiveProfileImageUrl,
                            fit: BoxFit.cover,
                            width: profilePicSize,
                            height: profilePicSize,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                app_placeholders.buildProfilePlaceholder(
                              name: widget.userName ?? "User",
                              size: profilePicSize,
                              borderRadius: borderRadius,
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.2),
                              textColor: theme.colorScheme.primary,
                              defaultIcon: Icons.person_rounded,
                            ),
                          ),
                  ),
                ),
              ),
              const Gap(16),

              // --- User Name ---
              Text(
                widget.userName ?? "User",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const Gap(8),

              // --- Instructions ---
              Text(
                _nfcAvailable
                    ? "Present this code to the scanner or use NFC for entry."
                    : "Present this code to the scanner for entry.",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
              const Gap(32),

              // --- Animated QR Code with Wireless Animation ---
              Stack(
                alignment: Alignment.center,
                children: [
                  // Wireless animation effect
                  WirelessAnimation(
                    size: 300,
                    color: theme.colorScheme.primary,
                    waveCount: 4,
                    opacity: 0.2,
                  ),

                  // QR code
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 210.0,
                        gapless: false,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: theme.colorScheme.onSurface,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: theme.colorScheme.onSurface,
                        ),
                        errorStateBuilder: (cxt, err) => const Center(
                          child: Text(
                            "Error generating QR code.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // NFC active indicator (small icon when NFC is active)
                  if (_nfcActive && _nfcAvailable)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.nfc_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(32),

              // --- Upcoming Events Section ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const Gap(8),
                        Text(
                          "Upcoming Events",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // Placeholder for upcoming events - would be replaced with actual data
                    // This would typically come from a BlocBuilder for events
                    _buildEventListItem(
                      theme,
                      "Your hair appointment",
                      DateTime.now().add(const Duration(days: 2)),
                      "Confirmed",
                      AppColors.accentColor,
                    ),
                    const Divider(height: 24),
                    _buildEventListItem(
                      theme,
                      "Salon visit",
                      DateTime.now().add(const Duration(days: 5)),
                      "Pending",
                      Colors.orange,
                    ),
                    const Gap(12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to all events/reservations
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "View All Events",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // --- Queue Status Section ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.queue,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const Gap(8),
                        Text(
                          "Your Queue Status",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // Active queue card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.people,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hair Salon Queue",
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Position: 3",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "Active",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.66,
                              backgroundColor: Colors.white,
                              color: AppColors.accentColor,
                              minHeight: 10,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            "Estimated wait time: 15 minutes",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  // Leave queue action
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Leave Queue?"),
                                      content: const Text(
                                        "Are you sure you want to leave this queue? You'll lose your position.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            // Handle leave queue action
                                            Navigator.pop(context);
                                            // Show confirmation
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "You've left the queue"),
                                              ),
                                            );
                                          },
                                          child: const Text("Leave Queue"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text("Leave Queue"),
                              ),
                              const Gap(8),
                              ElevatedButton(
                                onPressed: () {
                                  // View details action
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          QueueReservationPage(
                                        providerId: "placeholder",
                                        governorateId: "placeholder",
                                        serviceId: "placeholder",
                                        serviceName: "Hair Salon Queue",
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text("View Details"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    // Join new queue button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to queue selection
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Join New Queue"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // --- NFC Section ---
              BlocBuilder<AccessBloc, AccessState>(
                builder: (context, state) {
                  // Status message
                  String statusMessage;
                  if (!_nfcAvailable) {
                    statusMessage = "NFC is not available on this device";
                  } else if (_nfcActive) {
                    statusMessage = "NFC sharing is active";
                  } else if (_nfcScanning) {
                    statusMessage = "Scanning for NFC tag...";
                  } else {
                    statusMessage = "Tap to activate NFC sharing";
                  }

                  // Opacity for NFC section
                  double opacity = _nfcAvailable ? 1.0 : 0.6;

                  // NFC icon color
                  Color iconColor;
                  if (!_nfcAvailable) {
                    iconColor = theme.colorScheme.secondary;
                  } else if (_nfcActive) {
                    iconColor = AppColors.accentColor;
                  } else if (_nfcScanning) {
                    iconColor = AppColors.accentColor;
                  } else {
                    iconColor = theme.colorScheme.primary;
                  }

                  return Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      onTap: _nfcAvailable
                          ? (_nfcActive
                              ? () {
                                  setState(() {
                                    _nfcActive = false;
                                  });
                                  _stopNFCScanning();
                                }
                              : _activateNFC)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: _nfcAvailable
                              ? (_nfcActive
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.1))
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _nfcAvailable
                                ? (_nfcActive
                                    ? theme.colorScheme.primary.withOpacity(0.5)
                                    : theme.colorScheme.primary
                                        .withOpacity(0.3))
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.nfc_rounded,
                              color: iconColor,
                              size: 24,
                            ),
                            const Gap(12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nfcActive
                                        ? "NFC Active"
                                        : (_nfcScanning
                                            ? "Scanning..."
                                            : "NFC Access"),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: _nfcAvailable
                                          ? (_nfcActive
                                              ? AppColors.accentColor
                                              : theme.colorScheme.primary)
                                          : theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    statusMessage,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _nfcAvailable
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.secondary
                                              .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_nfcScanning || _nfcActive) ...[
                              const Gap(12),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: _nfcActive
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppColors.accentColor,
                                        size: 20,
                                      )
                                    : CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!widget.isBottomSheet) ...[
                const Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: theme.colorScheme.secondary),
                  label: Text("Close",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ] else ...[
                const Gap(20),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build event list items
  Widget _buildEventListItem(
    ThemeData theme,
    String title,
    DateTime eventDate,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.event_note,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(2),
              Text(
                "${eventDate.day}/${eventDate.month}/${eventDate.year} at ${eventDate.hour}:${eventDate.minute.toString().padLeft(2, '0')}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
