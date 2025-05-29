# Payment System - Stripe Integration

A clean, simplified payment system for ShamilApp using Stripe as the payment gateway.

## Overview

This payment system provides a streamlined integration with Stripe for handling reservations and subscription payments. The system has been simplified to focus only on essential functionality with clean, maintainable code.

## Architecture

```
lib/core/payment/
├── bloc/                          # Payment state management
│   ├── payment_bloc.dart         # Main payment BLoC
│   ├── payment_event.dart        # Payment events
│   └── payment_state.dart        # Payment states
├── config/                       # Configuration management
│   ├── payment_credentials_manager.dart  # Secure credential storage
│   └── payment_environment_config.dart   # Environment configuration
├── gateways/stripe/              # Stripe integration
│   └── stripe_service.dart      # Core Stripe service
├── models/                       # Payment data models
│   └── payment_models.dart      # All payment-related models
├── ui/                          # UI components
│   └── stripe_payment_widget.dart  # Modern payment widget
└── README.md                    # This file
```

## Features

### ✅ Implemented
- **Stripe Payment Processing**: Complete integration with Stripe for card payments
- **Reservation Payments**: Dedicated flow for service reservations
- **Subscription Payments**: Support for subscription-based payments
- **Secure Credential Management**: Encrypted storage of API keys
- **Environment Configuration**: Support for dev/staging/production environments
- **Modern UI Components**: Beautiful payment widget with card input
- **State Management**: BLoC pattern for reactive payment state
- **Error Handling**: Comprehensive error handling and user feedback

### 🎯 Core Components

#### 1. StripeService
- Payment intent creation and confirmation
- Saved payment methods management
- Payment verification and status tracking
- Secure API communication with Stripe

#### 2. PaymentBloc
- Reactive state management for payment flows
- Event-driven architecture for payment operations
- Integration with StripeService for payment processing

#### 3. StripePaymentWidget
- Modern, responsive payment UI
- Card input with real-time validation
- Support for saved payment methods
- Error handling and loading states

#### 4. Configuration Management
- Environment-specific credential storage
- Secure key management with encryption
- Fallback to hardcoded test credentials for development

## Setup Instructions

### 1. Dependencies
Ensure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_stripe: ^10.1.1
  flutter_secure_storage: ^9.0.0
  flutter_dotenv: ^5.1.0
  http: ^1.1.0
  bloc: ^8.1.2
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
```

### 2. Stripe Configuration
The system uses your provided test credentials:

```dart
// Development/Test credentials (already configured)
publishableKey: 'pk_test_51OMIxwB7R0ZlXV65QN5otHfPIzb51sK8nlZF5Gv7MuHf9rjKcXQoHMT5qXg8xurBJ1VnpIWCs7HmOkWJuCpEKkwt00uaCBogSC'
secretKey: 'sk_test_51OMIxwB7R0ZlXV65NvSCi17HCvmbrKarz5yZP5blPHsrbw4CvT65LUuq3x0IGOUmZdKSxGMCcL8y1p2GxhVZ2FmT00dhy2Nuiv'
```

### 3. Environment Variables (Optional)
Create `assets/env/.env` for custom configuration:

```env
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_...
STRIPE_SECRET_KEY_DEV=sk_test_...
STRIPE_WEBHOOK_SECRET_DEV=whsec_...

STRIPE_PUBLISHABLE_KEY_PROD=pk_live_...
STRIPE_SECRET_KEY_PROD=sk_live_...
STRIPE_WEBHOOK_SECRET_PROD=whsec_...

# Environment
PAYMENT_ENVIRONMENT=development
```

### 4. Initialization
Initialize the payment system in your app:

```dart
// In main.dart
await PaymentEnvironmentConfig.instance.initialize();
await PaymentCredentialsManager.instance.initializeWithStripeCredentials();
```

## Usage Examples

### 1. Reservation Payment
```dart
// In your reservation screen
StripePaymentWidget(
  paymentRequest: PaymentRequest(
    id: 'reservation_${reservationId}',
  amount: PaymentAmount(
      amount: totalAmount,
    currency: Currency.egp,
  ),
  customer: PaymentCustomer(
      id: userId,
      name: userName,
      email: userEmail,
    ),
    method: PaymentMethod.creditCard,
    gateway: PaymentGateway.stripe,
    description: 'Reservation payment',
    metadata: {
      'type': 'reservation',
      'reservation_id': reservationId,
    },
    createdAt: DateTime.now(),
  ),
  onPaymentComplete: (response) {
    if (response.isSuccessful) {
      // Handle success
    } else {
      // Handle failure
    }
  },
  onError: (error) {
    // Handle error
  },
  showSavedMethods: true,
  customerId: userId,
)
```

### 2. BLoC Integration
```dart
// Initialize payment BLoC
final paymentBloc = PaymentBloc();

// Add to your widget tree
BlocProvider(
  create: (context) => paymentBloc..add(InitializePayments()),
  child: YourPaymentScreen(),
)

// Listen to payment states
BlocListener<PaymentBloc, PaymentState>(
  listener: (context, state) {
    if (state is PaymentLoaded && state.lastPaymentResponse != null) {
      // Handle payment response
    }
  },
  child: YourWidget(),
)
```

## Security Considerations

### 🔒 Production Security
- **Never commit API keys** to version control
- **Use environment variables** for production credentials
- **Enable webhook signature verification** in production
- **Implement proper SSL/TLS** for API communications
- **Use secure storage** for sensitive data

### 🛡️ Current Security Features
- Encrypted credential storage using `flutter_secure_storage`
- Environment separation for different deployment stages
- Secure API communication with Stripe
- Input validation and sanitization

## Testing

### Test Cards (Stripe Test Mode)
```
Visa: 4242424242424242
Mastercard: 5555555555554444
Amex: 378282246310005
Declined: 4000000000000002
```

### Test Scenarios
- Successful payments
- Failed payments
- 3D Secure authentication
- Network errors
- Invalid card details

## Troubleshooting

### Common Issues

1. **"Stripe service not initialized"**
   - Ensure `StripeService.initialize()` is called before use
   - Check that credentials are properly configured

2. **"Invalid Stripe configuration"**
   - Verify publishable and secret keys are correct
   - Ensure keys match the environment (test/live)

3. **Payment confirmation fails**
   - Check network connectivity
   - Verify card details are valid
   - Check Stripe dashboard for error details

### Debug Mode
Enable debug logging:
```dart
// In debug mode, the system automatically prints configuration details
PaymentEnvironmentConfig.instance.printConfiguration();
```

## Deployment

### Production Checklist
- [ ] Replace test credentials with live Stripe keys
- [ ] Set `PAYMENT_ENVIRONMENT=production`
- [ ] Configure webhook endpoints
- [ ] Test with real payment methods
- [ ] Enable proper error monitoring
- [ ] Verify SSL certificates

### Environment Configuration
```dart
// Production environment detection
if (PaymentEnvironmentConfig.instance.currentEnvironment == PaymentEnvironment.production) {
  // Production-specific logic
}
```

## Support

For issues related to:
- **Stripe Integration**: Check [Stripe Documentation](https://stripe.com/docs)
- **Flutter Stripe Plugin**: Check [flutter_stripe package](https://pub.dev/packages/flutter_stripe)
- **App-specific Issues**: Review the implementation in this codebase

## License

This payment system is part of the ShamilApp project and follows the same licensing terms. 