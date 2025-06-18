import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import '../../models/configuration_step.dart';
import 'steps/booking_details_step.dart';
import 'steps/booking_preferences_step.dart';
import 'steps/booking_payment_step.dart';

/// Manages the content for each booking step
class BookingStepContent extends StatelessWidget {
  final PageController pageController;
  final int currentStep;
  final List<ConfigurationStep> steps;
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final Animation<double> contentAnimation;
  final String costSplitMethod;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final Function(int) onStepChanged;
  final Function(String) onCostSplitChanged;
  final VoidCallback onPaymentSuccess;
  final Function(String?) onPaymentFailure;
  final Function(VoidCallback?)? onPaymentTriggerReady;
  final Function(String)? onPaymentMethodChanged;

  const BookingStepContent({
    super.key,
    required this.pageController,
    required this.currentStep,
    required this.steps,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    required this.contentAnimation,
    required this.costSplitMethod,
    this.userId,
    this.userName,
    this.userEmail,
    required this.onStepChanged,
    required this.onCostSplitChanged,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.onPaymentTriggerReady,
    this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0E1A), // Match dark theme
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onStepChanged,
        itemCount: steps.length,
        itemBuilder: (context, index) => _buildStepContent(context, index),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, int stepIndex) {
    switch (stepIndex) {
      case 0:
        return BookingDetailsStep(
          state: state,
          provider: provider,
          service: service,
          plan: plan,
          contentAnimation: contentAnimation,
        );
      case 1:
        return BookingPreferencesStep(
          state: state,
          provider: provider,
          service: service,
          plan: plan,
          costSplitMethod: costSplitMethod,
          onCostSplitChanged: onCostSplitChanged,
          contentAnimation: contentAnimation,
        );
      case 2:
        return BookingPaymentStep(
          state: state,
          provider: provider,
          service: service,
          plan: plan,
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          contentAnimation: contentAnimation,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentFailure: onPaymentFailure,
          onPaymentTriggerReady: onPaymentTriggerReady,
          onPaymentMethodChanged: onPaymentMethodChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
