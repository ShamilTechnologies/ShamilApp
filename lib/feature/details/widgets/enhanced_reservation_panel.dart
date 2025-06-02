// lib/feature/details/widgets/enhanced_reservation_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/details/bloc/service_details_bloc.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

/// Enhanced reservation panel with full venue booking, cost splitting, and community hosting
class EnhancedReservationPanel extends StatefulWidget {
  final ServiceModel service;
  final bool isLoading;

  const EnhancedReservationPanel({
    super.key,
    required this.service,
    this.isLoading = false,
  });

  @override
  State<EnhancedReservationPanel> createState() => _EnhancedReservationPanelState();
}

class _EnhancedReservationPanelState extends State<EnhancedReservationPanel> {
  // Local state
  late DateTime _selectedDate;
  String? _selectedTimeSlot;
  bool _showCommunityOptions = false;
  final bool _showSplitOptions = false;
  bool _showAttendeeOptions = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form controls
  final _formKey = GlobalKey<FormState>();

  // Time slot options - In a real app these would be dynamically fetched
  final List<String> _timeSlots = [
    "10:00-11:00",
    "11:00-12:00",
    "12:00-13:00",
    "14:00-15:00",
    "15:00-16:00",
    "16:00-17:00",
  ];

  // Available categories for community hosting
  final List<String> _categories = [
    "Fitness",
    "Sports",
    "Entertainment",
    "Education",
    "Wellness",
    "Social",
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceDetailsBloc, ServiceDetailsState>(
      listener: (context, state) {
        if (state is ServiceDetailsConfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          
          // Close the panel after confirmation
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is ServiceDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isProcessing = state is ServiceDetailsProcessing;
        final reservationDetails = state is ServiceDetailsLoaded ? state.reservationDetails : null;
        final isFullVenue = reservationDetails?.isFullVenue ?? false;
        final capacity = reservationDetails?.reservedCapacity ?? 1;
        final isCommunityVisible = reservationDetails?.isCommunityVisible ?? false;
        
        return Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title and details
                Text(
                  widget.service.name,
                  style: AppTextStyle.getHeadlineTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Gap(8),
                
                Text(
                  'EGP ${widget.service.price.toStringAsFixed(2)}',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                if (widget.service.description.isNotEmpty) ...[
                  const Gap(12),
                  Text(
                    widget.service.description,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                
                const Divider(height: 32),
                
                // Venue capacity section
                _buildVenueCapacitySection(context, isFullVenue, capacity),
                
                const Divider(height: 32),
                
                // Date and time section
                _buildDateTimeSection(),
                
                const Divider(height: 32),
                
                // Attendees and cost splitting
                _buildAttendeeSection(
                  context, 
                  reservationDetails?.attendees ?? [], 
                  capacity, 
                  reservationDetails?.costSplitDetails,
                ),
                
                const Divider(height: 32),
                
                // Community hosting section
                _buildCommunityHostingSection(context, isCommunityVisible),
                
                const Gap(16),
                
                // Notes field
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                
                const Gap(24),
                
                // Book button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: isProcessing ? 'Processing...' : 'Book Now',
                    onPressed: (isProcessing || widget.isLoading) ? null : _handleBookNow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVenueCapacitySection(BuildContext context, bool isFullVenue, int capacity) {
    final bloc = context.read<ServiceDetailsBloc>();
    final state = bloc.state;
    
    if (state is! ServiceDetailsLoaded) return const SizedBox.shrink();
    
    // Get provider info for capacity limits
    final provider = state.providerDetails;
    final maxCapacity = provider.totalCapacity ?? provider.maxGroupSize ?? 20;
    final minCapacity = provider.minGroupSize ?? 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Booking',
          style: AppTextStyle.getTitleStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const Gap(12),
        
        // Full venue toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Book Entire Venue',
            style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Reserve the entire space for your exclusive use',
            style: AppTextStyle.getSmallStyle(color: AppColors.secondaryText),
          ),
          value: isFullVenue,
          onChanged: (bool value) {
            bloc.add(SetReservationCapacity(
              isFullVenue: value,
              capacity: value ? maxCapacity : minCapacity,
            ));
          },
          activeColor: AppColors.primaryColor,
        ),
        
        // Capacity slider (only show if not full venue)
        if (!isFullVenue) ...[
          const Gap(8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capacity: $capacity',
                style: AppTextStyle.getbodyStyle(),
              ),
              Text(
                'Max: $maxCapacity',
                style: AppTextStyle.getSmallStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
          
          const Gap(8),
          
          Slider(
            min: minCapacity.toDouble(),
            max: maxCapacity.toDouble(),
            divisions: maxCapacity - minCapacity,
            value: capacity.toDouble(),
            onChanged: (value) {
              bloc.add(SetReservationCapacity(
                isFullVenue: false,
                capacity: value.round(),
              ));
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: AppTextStyle.getTitleStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const Gap(16),
        
        // Date picker button
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.calendar, color: AppColors.primaryColor),
                const Gap(12),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: AppTextStyle.getbodyStyle(),
                ),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_down, size: 16),
              ],
            ),
          ),
        ),
        
        const Gap(16),
        
        // Time slot selection
        Text(
          'Select Time Slot:',
          style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w500),
        ),
        
        const Gap(8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((timeSlot) {
            final isSelected = _selectedTimeSlot == timeSlot;
            return ChoiceChip(
              label: Text(timeSlot),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? timeSlot : null;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryColor : AppColors.primaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttendeeSection(
    BuildContext context, 
    List<AttendeeModel> attendees,
    int capacity,
    Map<String, dynamic>? costSplitDetails,
  ) {
    final bloc = context.read<ServiceDetailsBloc>();
    final bool splitEnabled = costSplitDetails?['enabled'] ?? false;
    final String splitMethod = costSplitDetails?['splitMethod'] ?? 'equal';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendees & Payment',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAttendeeOptions = !_showAttendeeOptions;
                });
              },
              child: Text(
                _showAttendeeOptions ? 'Hide Options' : 'Show Options',
                style: const TextStyle(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
        
        if (_showAttendeeOptions) ...[
          // Attendee list
          if (attendees.isNotEmpty) ...[
            const Gap(12),
            
            ...attendees.map((attendee) {
              final isSelf = attendee.type == 'self';
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(attendee.name.isNotEmpty 
                      ? attendee.name[0].toUpperCase() 
                      : '?'),
                ),
                title: Text(
                  attendee.name + (isSelf ? ' (You)' : ''),
                  style: AppTextStyle.getbodyStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _getPaymentStatusText(attendee, splitEnabled, splitMethod),
                  style: AppTextStyle.getSmallStyle(
                    color: _getPaymentStatusColor(attendee.paymentStatus),
                  ),
                ),
                trailing: isSelf ? null : IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle),
                  onPressed: () {
                    // Remove attendee action
                    // Logic to remove attendee would go here
                  },
                ),
              );
            }),
            
            const Gap(16),
          ],
          
          // Add attendee button
          OutlinedButton.icon(
            onPressed: () {
              // Show dialog to add attendee
              _showAddAttendeeDialog(context);
            },
            icon: const Icon(CupertinoIcons.person_add),
            label: const Text('Add Attendee'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const Gap(20),
          
          // Cost splitting options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.money_dollar_circle, color: AppColors.primaryColor),
                    const Gap(8),
                    Text(
                      'Cost Splitting',
                      style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Switch(
                      value: splitEnabled,
                      onChanged: (value) {
                        bloc.add(UpdateCostSplitting(
                          enabled: value,
                          method: splitMethod,
                        ));
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                  ],
                ),
                
                if (splitEnabled) ...[
                  const Gap(12),
                  
                  // Split methods
                  DropdownButtonFormField<String>(
                    value: splitMethod,
                    decoration: const InputDecoration(
                      labelText: 'Split Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'equal', child: Text('Equal Split')),
                      DropdownMenuItem(value: 'host_pays', child: Text('You Pay All')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom Split')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        bloc.add(UpdateCostSplitting(
                          enabled: true,
                          method: value,
                        ));
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommunityHostingSection(BuildContext context, bool isCommunityVisible) {
    final bloc = context.read<ServiceDetailsBloc>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Hosting',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showCommunityOptions = !_showCommunityOptions;
                });
              },
              child: Text(
                _showCommunityOptions ? 'Hide Options' : 'Show Options',
                style: const TextStyle(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
        
        const Gap(8),
        
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Make This Event Public',
            style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Allow others to join your reservation',
            style: AppTextStyle.getSmallStyle(color: AppColors.secondaryText),
          ),
          value: isCommunityVisible,
          onChanged: (bool value) {
            bloc.add(SetCommunityVisibility(
              isVisible: value,
              category: value ? _categories.first : null,
            ));
            
            if (value && !_showCommunityOptions) {
              setState(() {
                _showCommunityOptions = true;
              });
            }
          },
          activeColor: AppColors.primaryColor,
        ),
        
        if (isCommunityVisible && _showCommunityOptions) ...[
          const Gap(16),
          
          // Category dropdown
          DropdownButtonFormField<String>(
            value: _categories.first,
            decoration: const InputDecoration(
              labelText: 'Event Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) => 
              DropdownMenuItem(value: category, child: Text(category))
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                bloc.add(SetCommunityVisibility(
                  isVisible: true,
                  category: value, 
                  description: _descriptionController.text,
                ));
              }
            },
          ),
          
          const Gap(16),
          
          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Event Description',
              hintText: 'Tell others about your event',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              // Update description when changed
              bloc.add(SetCommunityVisibility(
                isVisible: true,
                category: _categories.first,
                description: value,
              ));
            },
          ),
        ],
      ],
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddAttendeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Attendee'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter attendee name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                // Create a new attendee
                final newAttendee = AttendeeModel(
                  userId: UniqueKey().toString(), // Generate temporary ID
                  name: nameController.text.trim(),
                  type: 'guest',
                  status: 'going',
                  paymentStatus: PaymentStatus.pending,
                );
                
                // Add attendee
                context.read<ServiceDetailsBloc>().add(SetAttendeePayment(
                  attendeeId: newAttendee.userId,
                  status: PaymentStatus.pending,
                  attendee: newAttendee,
                ));
                
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleBookNow() {
    if (_formKey.currentState?.validate() == true && _selectedTimeSlot != null) {
      // Get current notes
      final notes = _notesController.text.trim();
      
      // Create the reservation
      context.read<ServiceDetailsBloc>().add(InitiateReservation(
        date: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        notes: notes.isNotEmpty ? notes : null,
      ));
    } else {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPaymentStatusText(AttendeeModel attendee, bool splitEnabled, String splitMethod) {
    if (!splitEnabled) {
      return attendee.type == 'self' ? 'Paying full amount' : 'Not paying';
    }
    
    switch (attendee.paymentStatus) {
      case PaymentStatus.complete:
        return 'Paid in full';
      case PaymentStatus.partial:
        return 'Partially paid';
      case PaymentStatus.pending:
        return splitMethod == 'equal' 
            ? 'Will pay equal share' 
            : (splitMethod == 'host_pays' && attendee.type != 'self')
                ? 'Host is paying'
                : 'Payment pending';
      case PaymentStatus.hosted:
        return 'Hosted by someone else';
      case PaymentStatus.waived:
        return 'Payment waived';
      default:
        return 'Payment pending';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.complete:
        return AppColors.greenColor;
      case PaymentStatus.partial:
        return Colors.orange;
      case PaymentStatus.pending:
        return AppColors.secondaryText;
      case PaymentStatus.hosted:
        return AppColors.cyanColor;
      case PaymentStatus.waived:
        return AppColors.purpleColor;
      default:
        return AppColors.secondaryText;
    }
  }
}