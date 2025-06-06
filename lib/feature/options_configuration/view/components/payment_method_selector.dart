import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

/// Payment Method Selector Component
class PaymentMethodSelector extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(String) onPaymentMethodChanged;
  final VoidCallback onPaymentInitiated;

  const PaymentMethodSelector({
    super.key,
    required this.state,
    required this.onPaymentMethodChanged,
    required this.onPaymentInitiated,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  String _selectedMethod = 'creditCard';

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'creditCard',
      name: 'Credit Card',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primaryColor,
    ),
    PaymentMethod(
      id: 'debitCard',
      name: 'Debit Card',
      icon: CupertinoIcons.creditcard,
      color: AppColors.cyanColor,
    ),
    PaymentMethod(
      id: 'cash',
      name: 'Pay on Arrival',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: AppColors.greenColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Gap(20),
          _buildPaymentMethods(),
          const Gap(24),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.greenColor, AppColors.primaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            CupertinoIcons.creditcard_fill,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                'Choose how you\'d like to pay',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.lightText.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: _paymentMethods.map(_buildPaymentMethodOption).toList(),
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method) {
    final isSelected = _selectedMethod == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedMethod = method.id);
            widget.onPaymentMethodChanged(method.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        method.color.withOpacity(0.2),
                        method.color.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: !isSelected ? Colors.white.withOpacity(0.05) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? method.color.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              method.color,
                              method.color.withOpacity(0.8)
                            ],
                          )
                        : null,
                    color: !isSelected ? Colors.white.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method.icon,
                    color: isSelected
                        ? Colors.white
                        : AppColors.lightText.withOpacity(0.6),
                    size: 20,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    method.name,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: method.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.onPaymentInitiated,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.greenColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.lock_fill, size: 20),
            const Gap(12),
            Text(
              'Pay EGP ${widget.state.totalPrice.toStringAsFixed(0)}',
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
