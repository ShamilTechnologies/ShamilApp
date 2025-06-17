import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/components/attendee_manager.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/components/date_time_selector.dart';
import '../shared/premium_card.dart';
import '../shared/step_header.dart';

/// First step: Booking details (date, time & attendees)
class BookingDetailsStep extends StatelessWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final Animation<double> contentAnimation;

  const BookingDetailsStep({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    required this.contentAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - contentAnimation.value)),
          child: Opacity(
            opacity: contentAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepHeader(
                    title: 'Booking Details',
                    subtitle: 'Choose your perfect booking time and attendees',
                  ),
                  const Gap(24),
                  _buildDateTimeCard(context),
                  const Gap(24),
                  _buildAttendeesCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return PremiumCard(
      icon: CupertinoIcons.calendar_today,
      title: 'Date & Time',
      subtitle: 'Choose your perfect booking time',
      gradient: [
        const Color(0xFF0A0E1A),
        AppColors.primaryColor.withOpacity(0.15),
        AppColors.tealColor.withOpacity(0.1),
      ],
      shadowColor: AppColors.primaryColor,
      child: DateTimeSelector(
        state: state,
        provider: provider,
        service: service,
        plan: plan,
        onDateChanged: (date) {
          context.read<OptionsConfigurationBloc>().add(
                DateSelected(selectedDate: date),
              );
        },
        onTimeChanged: (time) {
          context.read<OptionsConfigurationBloc>().add(
                TimeSelected(selectedTime: time),
              );
        },
      ),
    );
  }

  Widget _buildAttendeesCard(BuildContext context) {
    return PremiumCard(
      icon: CupertinoIcons.person_2_fill,
      title: 'Attendees',
      subtitle: 'Who will be joining you?',
      gradient: [
        const Color(0xFF0A0E1A),
        AppColors.tealColor.withOpacity(0.15),
        AppColors.successColor.withOpacity(0.1),
      ],
      shadowColor: AppColors.tealColor,
      badge: state.selectedAttendees.isNotEmpty
          ? '${state.selectedAttendees.length} ${state.selectedAttendees.length == 1 ? 'Person' : 'People'}'
          : null,
      child: AttendeeManager(
        state: state,
        onAttendeeAdded: (attendee) {
          context.read<OptionsConfigurationBloc>().add(
                AddOptionAttendee(attendee: attendee),
              );
        },
        onAttendeeRemoved: (userId) {
          context.read<OptionsConfigurationBloc>().add(
                RemoveOptionAttendee(attendeeUserId: userId),
              );
        },
        onAttendeeUpdated: (attendee) {
          // Update functionality not implemented in options configuration
          // Could be added later if needed
        },
      ),
    );
  }
}
