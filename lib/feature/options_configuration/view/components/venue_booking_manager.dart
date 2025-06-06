import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';

/// Venue Booking Manager Component
class VenueBookingManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(VenueBookingConfig) onVenueConfigChanged;

  const VenueBookingManager({
    super.key,
    required this.state,
    required this.onVenueConfigChanged,
  });

  @override
  State<VenueBookingManager> createState() => _VenueBookingManagerState();
}

class _VenueBookingManagerState extends State<VenueBookingManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedVenueType = 'provider';
  bool _hasVenuePreference = false;
  String _venueLocation = '';
  String _venueNotes = '';
  List<String> _venueAmenities = [];

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<VenueType> _venueTypes = [
    VenueType(
      id: 'provider',
      title: 'Provider Location',
      subtitle: 'Use service provider\'s venue',
      icon: CupertinoIcons.building_2_fill,
      color: AppColors.primaryColor,
    ),
    VenueType(
      id: 'customer',
      title: 'Your Location',
      subtitle: 'Service at your place',
      icon: CupertinoIcons.house_fill,
      color: AppColors.tealColor,
    ),
    VenueType(
      id: 'custom',
      title: 'Custom Location',
      subtitle: 'Specify a different venue',
      icon: CupertinoIcons.location_fill,
      color: AppColors.cyanColor,
    ),
  ];

  final List<String> _availableAmenities = [
    'Parking Available',
    'WiFi Access',
    'Air Conditioning',
    'Audio System',
    'Projector/Screen',
    'Catering Services',
    'Photography Area',
    'Accessibility Features',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialState();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_cardAnimation);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  void _setupInitialState() {
    if (widget.state.venueBookingConfig != null) {
      final config = widget.state.venueBookingConfig!;
      // Use actual VenueBookingConfig properties
      _selectedVenueType =
          config.type == VenueBookingType.fullVenue ? 'provider' : 'custom';
      _hasVenuePreference = config.isPrivateEvent;

      _locationController.text = _venueLocation;
      _notesController.text = _venueNotes;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateVenueConfig() {
    final config = VenueBookingConfig(
      type: _selectedVenueType == 'provider'
          ? VenueBookingType.fullVenue
          : VenueBookingType.partialCapacity,
      capacity: 50, // Default capacity
      price: 0.0, // Will be calculated later
      maxCapacity: 100, // Default max capacity
      isPrivateEvent: _hasVenuePreference,
      selectedCapacity: _selectedVenueType == 'custom' ? 20 : null,
    );
    widget.onVenueConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVenueTypeSelector(),
            if (_selectedVenueType == 'custom') ...[
              const Gap(20),
              _buildLocationInput(),
            ],
            const Gap(20),
            _buildVenuePreferences(),
            if (_hasVenuePreference) ...[
              const Gap(20),
              _buildAmenitiesSelector(),
              const Gap(20),
              _buildNotesInput(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVenueTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venue Selection',
                        style: app_text_style.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Choose your preferred venue type',
                        style: app_text_style.getbodyStyle(
                          color: AppColors.lightText.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: _venueTypes.map((venueType) {
                return _buildVenueTypeCard(venueType);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueTypeCard(VenueType venueType) {
    final isSelected = _selectedVenueType == venueType.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedVenueType = venueType.id;
        });
        _updateVenueConfig();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    venueType.color.withOpacity(0.2),
                    venueType.color.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? venueType.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? venueType.color
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  venueType.icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withOpacity(0.7),
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueType.title,
                      style: app_text_style.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      venueType.subtitle,
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: venueType.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Details',
              style: app_text_style.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _locationController,
                onChanged: (value) {
                  _venueLocation = value;
                  _updateVenueConfig();
                },
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter venue address or location',
                  hintStyle: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    CupertinoIcons.location,
                    color: AppColors.lightText.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuePreferences() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealColor, AppColors.cyanColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.slider_horizontal_3,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venue Preferences',
                    style: app_text_style.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Specify amenities and requirements',
                    style: app_text_style.getbodyStyle(
                      color: AppColors.lightText.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _hasVenuePreference,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _hasVenuePreference = value;
                });
                _updateVenueConfig();
              },
              activeColor: AppColors.tealColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Required Amenities',
              style: app_text_style.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAmenities.map((amenity) {
                final isSelected = _venueAmenities.contains(amenity);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isSelected) {
                        _venueAmenities.remove(amenity);
                      } else {
                        _venueAmenities.add(amenity);
                      }
                    });
                    _updateVenueConfig();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppColors.tealColor,
                                AppColors.cyanColor,
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      amenity,
                      style: app_text_style.getbodyStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.lightText.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Requests',
              style: app_text_style.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Text(
              'Any specific venue requirements or requests',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const Gap(12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _notesController,
                onChanged: (value) {
                  _venueNotes = value;
                  _updateVenueConfig();
                },
                maxLines: 3,
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter any special venue requirements...',
                  hintStyle: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VenueType {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const VenueType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
