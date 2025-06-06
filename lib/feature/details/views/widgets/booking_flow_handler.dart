import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/views/provider_services_screen.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';

class BookingFlowHandler {
  /// Navigate directly to the provider services screen for booking/subscription
  static void showBookingOptions(
      BuildContext context, ServiceProviderModel provider) {
    if (!provider.canBookOrSubscribeOnlineInDetail) {
      showGlobalSnackBar(
        context,
        "Online booking/subscription not available for this provider.",
        isError: false,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Navigate directly to the provider services screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderServicesScreen(provider: provider),
      ),
    );
  }
}
