
  import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

Widget _buildWelcomeText({
    required double topPadding,
    required double fixedHeight,
    required String welcomeText,
    required double welcomeFontSize,
    required bool isKeyboardOpen,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
        height: fixedHeight,
        alignment: Alignment.centerLeft,
        child: SmoothTypingText(
          key: ValueKey(isKeyboardOpen),
          text: welcomeText,
          style: getbodyStyle(
            height: 1,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: welcomeFontSize,
          ),
        ),
      ),
    );
  }