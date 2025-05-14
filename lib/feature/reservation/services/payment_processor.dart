import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

enum PaymentMethod { creditCard, cash, bankTransfer, mobileWallet }

class PaymentProcessor extends StatefulWidget {
  final ReservationModel reservation;
  final Function(PaymentStatus, String) onPaymentComplete;

  const PaymentProcessor({
    Key? key,
    required this.reservation,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentProcessor> createState() => _PaymentProcessorState();
}

class _PaymentProcessorState extends State<PaymentProcessor> {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  bool _processing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Payment',
            style: getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 24),
          _buildPaymentForm(),
          const SizedBox(height: 24),
          _buildPaymentButton(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: getbodyStyle(
                  color: AppColors.redColor,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: getTitleStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PaymentMethod.values.map((method) {
            return ChoiceChip(
              label: Text(method.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ')),
              selected: _selectedMethod == method,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMethod = method);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedMethod) {
      case PaymentMethod.creditCard:
        return _buildCreditCardForm();
      case PaymentMethod.cash:
        return _buildCashPaymentInfo();
      case PaymentMethod.bankTransfer:
        return _buildBankTransferInfo();
      case PaymentMethod.mobileWallet:
        return _buildMobileWalletForm();
    }
  }

  Widget _buildCreditCardForm() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay at Venue',
            style: getTitleStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please bring exact change when you arrive at the venue.',
            style: getbodyStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Transfer Details',
            style: getTitleStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please transfer the amount to the following account:\n'
            'Bank: Example Bank\n'
            'Account: 1234567890\n'
            'Reference: ${widget.reservation.id}',
            style: getbodyStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileWalletForm() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Wallet PIN',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _processing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Pay ${widget.reservation.totalPrice?.toStringAsFixed(2) ?? "0.00"}',
                style: getbodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Call the callback with success
      widget.onPaymentComplete(PaymentStatus.complete, 'Payment successful');
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }
}
