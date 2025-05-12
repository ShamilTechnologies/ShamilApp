// lib/feature/reservation/presentation/widgets/venue_capacity_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;

class VenueCapacitySelector extends StatefulWidget {
  /// The total capacity of the venue
  final int totalCapacity;
  
  /// Currently selected capacity (null if full venue)
  final int? selectedCapacity;
  
  /// Whether the current selection is for the full venue
  final bool isFullVenue;
  
  /// Minimum capacity that can be reserved (defaults to 1)
  final int minCapacity;
  
  /// Price per unit (e.g., per person, per seat)
  final double? pricePerUnit;
  
  /// Currency symbol to display (e.g., 'EGP ', '$')
  final String currencySymbol;
  
  /// Callback when selection changes
  final Function(bool isFullVenue, int? capacity) onCapacityChanged;
  
  /// Description of the venue capacity (optional)
  final String? capacityDescription;

  const VenueCapacitySelector({
    Key? key,
    required this.totalCapacity,
    this.selectedCapacity,
    required this.isFullVenue,
    this.minCapacity = 1,
    this.pricePerUnit,
    this.currencySymbol = 'EGP ',
    required this.onCapacityChanged,
    this.capacityDescription,
  }) : assert(totalCapacity >= minCapacity),
       super(key: key);

  @override
  State<VenueCapacitySelector> createState() => _VenueCapacitySelectorState();
}

class _VenueCapacitySelectorState extends State<VenueCapacitySelector> {
  late TextEditingController _capacityController;
  late bool _isFullVenue;
  int? _selectedCapacity;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isFullVenue = widget.isFullVenue;
    _selectedCapacity = widget.selectedCapacity ?? widget.minCapacity;
    _capacityController = TextEditingController(
      text: _selectedCapacity?.toString() ?? widget.minCapacity.toString()
    );
    
    // Add listener to update selectedCapacity when text changes
    _capacityController.addListener(_updateCapacityFromText);
  }
  
  @override
  void dispose() {
    _capacityController.removeListener(_updateCapacityFromText);
    _capacityController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(VenueCapacitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update if external state changes
    if (widget.isFullVenue != oldWidget.isFullVenue ||
        widget.selectedCapacity != oldWidget.selectedCapacity) {
      _isFullVenue = widget.isFullVenue;
      _selectedCapacity = widget.selectedCapacity;
      
      // Only update controller if we're not currently editing to avoid jumps
      if (!_isEditing && widget.selectedCapacity != null) {
        _capacityController.text = widget.selectedCapacity.toString();
      }
    }
  }
  
  void _updateCapacityFromText() {
    if (_capacityController.text.isEmpty) return;
    
    final parsed = int.tryParse(_capacityController.text);
    if (parsed != null && parsed != _selectedCapacity) {
      // Clamp value between min and max
      final clampedValue = parsed.clamp(widget.minCapacity, widget.totalCapacity);
      
      // Only update if different to avoid infinite loops
      if (clampedValue != parsed) {
        _capacityController.text = clampedValue.toString();
        _capacityController.selection = TextSelection.fromPosition(
          TextPosition(offset: clampedValue.toString().length)
        );
      }
      
      setState(() {
        _selectedCapacity = clampedValue;
      });
      
      // Notify parent without triggering full venue mode
      if (!_isFullVenue) {
        widget.onCapacityChanged(false, clampedValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.person_3_fill,
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
                        "Venue Capacity",
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.capacityDescription != null) ...[
                        const Gap(4),
                        Text(
                          widget.capacityDescription!,
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  "Total: ${widget.totalCapacity}",
                  style: AppTextStyle.getbodyStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            
            const Gap(20),
            
            // Full venue option
            _buildSelectionOption(
              title: "Reserve Entire Venue",
              description: "Book the entire venue for your exclusive use",
              isSelected: _isFullVenue,
              icon: CupertinoIcons.building_2_fill,
              price: widget.pricePerUnit != null 
                  ? "${widget.currencySymbol}${(widget.pricePerUnit! * widget.totalCapacity).toStringAsFixed(2)}" 
                  : null,
              onTap: () {
                setState(() {
                  _isFullVenue = true;
                });
                widget.onCapacityChanged(true, widget.totalCapacity);
              },
            ),
            
            const Gap(16),
            
            // Partial reservation option
            _buildSelectionOption(
              title: "Partial Reservation",
              description: "Reserve specific capacity only",
              isSelected: !_isFullVenue,
              icon: CupertinoIcons.person_2_fill,
              price: (widget.pricePerUnit != null && _selectedCapacity != null)
                  ? "${widget.currencySymbol}${(widget.pricePerUnit! * _selectedCapacity!).toStringAsFixed(2)}" 
                  : null,
              onTap: () {
                setState(() {
                  _isFullVenue = false;
                });
                widget.onCapacityChanged(false, _selectedCapacity);
              },
              trailingWidget: !_isFullVenue ? _buildCapacityInput() : null,
            ),
            
            // Capacity slider (only visible when partial is selected)
            if (!_isFullVenue) ...[
              const Gap(16),
              _buildCapacitySlider(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCapacityInput() {
    return SizedBox(
      width: 70,
      height: 36,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isEditing = hasFocus;
          });
        },
        child: TextField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
          style: AppTextStyle.getTitleStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              widget.totalCapacity.toString().length
            ),
          ],
          onEditingComplete: () {
            if (_capacityController.text.isEmpty) {
              _capacityController.text = widget.minCapacity.toString();
            }
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }
  
  Widget _buildCapacitySlider() {
    final currentValue = _selectedCapacity?.toDouble() ?? widget.minCapacity.toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Min: ${widget.minCapacity}",
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
              ),
            ),
            Text(
              "Max: ${widget.totalCapacity}",
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primaryColor,
            inactiveTrackColor: AppColors.primaryColor.withOpacity(0.2),
            thumbColor: AppColors.primaryColor,
            overlayColor: AppColors.primaryColor.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            min: widget.minCapacity.toDouble(),
            max: widget.totalCapacity.toDouble(),
            value: currentValue.clamp(
              widget.minCapacity.toDouble(), 
              widget.totalCapacity.toDouble()
            ),
            divisions: (widget.totalCapacity - widget.minCapacity) > 100 
                ? 100 
                : (widget.totalCapacity - widget.minCapacity),
            onChanged: (value) {
              final newValue = value.round();
              setState(() {
                _selectedCapacity = newValue;
                _capacityController.text = newValue.toString();
              });
              widget.onCapacityChanged(false, newValue);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSelectionOption({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    String? price,
    Widget? trailingWidget,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryColor.withOpacity(0.05) 
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryColor 
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? AppColors.primaryColor 
                    : Colors.grey.shade600,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppColors.primaryColor 
                          : Colors.black,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    description,
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (price != null) ...[
                    const Gap(4),
                    Text(
                      price,
                      style: AppTextStyle.getSmallStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? AppColors.primaryColor 
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              trailingWidget,
            ] else ...[
              Radio(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}