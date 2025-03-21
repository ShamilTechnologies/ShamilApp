
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

class ButtonArea extends StatelessWidget {
  const ButtonArea({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
            padding:
                const EdgeInsets.only(left: 30, right: 30, bottom: 30),
            child: CustomButton(
              text: "One Tap To Unlock",
              color: AppColors.primaryColor,
              onPressed: () {
                pushReplacement(context, const LoginView());
              },
            )));
  }
}
