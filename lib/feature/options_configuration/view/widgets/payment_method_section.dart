import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:gap/gap.dart';

class PaymentMethodSection extends StatelessWidget {
  final OptionsConfigurationState state;

  const PaymentMethodSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.creditcard,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Payment Method",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Payment method selection
            _buildPaymentMethods(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentMethodTile(
          context,
          'creditCard',
          Icons.credit_card,
          'Credit Card',
          'Pay securely with your credit or debit card',
        ),
        const Divider(),
        _buildPaymentMethodTile(
          context,
          'cash',
          Icons.money,
          'Cash',
          'Pay in cash when you arrive at the venue',
        ),
        const Divider(),
        _buildPaymentMethodTile(
          context,
          'bankTransfer',
          Icons.account_balance,
          'Bank Transfer',
          'Pay via bank transfer',
        ),
        const Divider(),
        _buildPaymentMethodTile(
          context,
          'mobileWallet',
          Icons.phone_android,
          'Mobile Wallet',
          'Pay using your mobile wallet',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    BuildContext context,
    String methodId,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = state.paymentMethod == methodId;

    return InkWell(
      onTap: () {
        context.read<OptionsConfigurationBloc>().add(
              UpdatePaymentMethod(paymentMethod: methodId),
            );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
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
                    style: AppTextStyle.getTitleStyle(fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyle.getSmallStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
