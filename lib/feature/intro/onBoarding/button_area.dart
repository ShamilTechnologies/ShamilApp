import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
// *** ADD Import for local storage ***
import 'package:shamil_mobile_app/core/services/local_storage.dart';

class ButtonArea extends StatelessWidget {
  const ButtonArea({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
            child: CustomButton(
              text: "One Tap To Unlock", // Or "Get Started", etc.
              color: AppColors.primaryColor,
              // *** Make onPressed async and add logic ***
              onPressed: () async {
                // Make async
                try {
                  // *** ADD THIS LINE to save the flag ***
                  await AppLocalStorage.cacheData(
                      key: AppLocalStorage
                          .isOnboardingShown, // Ensure this key is correct
                      value: true);
                  print("OnboardingShown flag SET to true."); // For debugging

                  // Navigate to Login screen AFTER saving the flag
                  if (context.mounted) {
                    // Check mounted after await
                    context.toSignIn(const LoginView());
                  }
                } catch (e) {
                  print("Error saving onboarding flag or navigating: $e");
                  // Optionally show an error message to the user
                  // showGlobalSnackBar(context, "Could not proceed, please try again.", isError: true);
                }
              },
            )));
  }
}
