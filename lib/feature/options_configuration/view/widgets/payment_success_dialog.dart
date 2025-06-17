import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Premium payment result dialog
class PaymentSuccessDialog {
  static void show({
    required BuildContext context,
    bool isSuccess = true,
    String? title,
    String? message,
    required VoidCallback onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(isSuccess),
            const Gap(20),
            _buildTitle(title, isSuccess),
            const Gap(12),
            _buildMessage(message, isSuccess),
            const Gap(24),
            _buildActionButton(context, isSuccess, onClose),
          ],
        ),
      ),
    );
  }

  static Widget _buildIcon(bool isSuccess) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        size: 50,
        color: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  static Widget _buildTitle(String? title, bool isSuccess) {
    return Text(
      title ?? (isSuccess ? 'Payment Successful!' : 'Payment Failed'),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  static Widget _buildMessage(String? message, bool isSuccess) {
    final defaultMessage = isSuccess
        ? 'Your booking has been confirmed. You will receive a confirmation email shortly.'
        : 'Something went wrong with your payment. Please try again.';

    return Text(
      message ?? defaultMessage,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  static Widget _buildActionButton(
    BuildContext context,
    bool isSuccess,
    VoidCallback onClose,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isSuccess ? Colors.green : AppColors.tealColor,
            isSuccess
                ? Colors.green.withOpacity(0.8)
                : AppColors.tealColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? Colors.green : AppColors.tealColor)
                .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              isSuccess ? 'Continue' : 'Try Again',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
