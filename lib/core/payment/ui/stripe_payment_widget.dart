import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../models/payment_models.dart';
import '../gateways/stripe/stripe_service.dart';

/// A modern, comprehensive Stripe payment widget that handles card payments,
/// saved payment methods, and provides a smooth user experience.
class StripePaymentWidget extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final Function(PaymentResponse) onPaymentComplete;
  final Function(String)? onError;
  final bool showSavedMethods;
  final String? customerId;
  final VoidCallback? onCancel;

  const StripePaymentWidget({
    super.key,
    required this.paymentRequest,
    required this.onPaymentComplete,
    this.onError,
    this.showSavedMethods = true,
    this.customerId,
    this.onCancel,
  });

  @override
  State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  final StripeService _stripeService = StripeService();
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodData> _savedMethods = [];
  PaymentMethodData? _selectedSavedMethod;
  bool _showCardForm = true;

  @override
  void initState() {
    super.initState();
    if (widget.showSavedMethods && widget.customerId != null) {
      _loadSavedPaymentMethods();
    }
  }

  Future<void> _loadSavedPaymentMethods() async {
    try {
      final methods = await _stripeService.getSavedPaymentMethods(
        customerId: widget.customerId!,
      );
      setState(() {
        _savedMethods = methods;
        if (_savedMethods.isNotEmpty) {
          _showCardForm = false;
        }
      });
    } catch (e) {
      // Silently handle error - user can still enter new card
    }
  }

  Future<void> _processPayment() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      PaymentResponse response;

      if (_selectedSavedMethod != null) {
        // For saved payment methods, we need to create a payment intent
        // and confirm it with the saved payment method
        response = await _stripeService.createReservationPayment(
          reservationId: widget.paymentRequest.id,
          amount: widget.paymentRequest.amount.amount,
          currency: widget.paymentRequest.amount.currency,
          customer: widget.paymentRequest.customer,
          description: widget.paymentRequest.description,
          metadata: widget.paymentRequest.metadata,
        );
      } else {
        // For new card payments, create payment intent for reservation
        response = await _stripeService.createReservationPayment(
          reservationId: widget.paymentRequest.id,
          amount: widget.paymentRequest.amount.amount,
          currency: widget.paymentRequest.amount.currency,
          customer: widget.paymentRequest.customer,
          description: widget.paymentRequest.description,
          metadata: widget.paymentRequest.metadata,
        );
      }

      widget.onPaymentComplete(response);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${widget.paymentRequest.amount.currency.symbol}${widget.paymentRequest.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment method selection
          if (_savedMethods.isNotEmpty) ...[
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Saved methods
            ...(_savedMethods.map((method) => _buildSavedMethodTile(method))),

            // Add new card option
            _buildNewCardOption(),
            const SizedBox(height: 16),
          ],

          // Card form (shown when no saved methods or user chooses new card)
          if (_showCardForm) ...[
            Text(
              'Card Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: stripe.CardField(
                onCardChanged: (card) {
                  // Handle card changes if needed
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pay button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Pay ${widget.paymentRequest.amount.currency.symbol}${widget.paymentRequest.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Security notice
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMethodTile(PaymentMethodData method) {
    final isSelected = _selectedSavedMethod?.id == method.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSavedMethod = isSelected ? null : method;
          _showCardForm = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _getCardIcon(method.brand),
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** **** **** ${method.last4 ?? '****'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  Text(
                    '${method.brand?.toUpperCase() ?? 'CARD'} • Expires ${method.expMonth?.toString().padLeft(2, '0')}/${method.expYear?.toString().substring(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardOption() {
    final isSelected = _showCardForm;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showCardForm = true;
          _selectedSavedMethod = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_card,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Use new card',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}
 