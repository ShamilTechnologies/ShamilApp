// lib/feature/options_configuration/view/options_configuration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';

// BLoC
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/options_configuration_event.dart';

// Models (ensure these paths are correct for your project)

class OptionsConfigurationScreen extends StatelessWidget {
  final String providerId;
  final PlanModel? plan;
  final ServiceModel? service;

  const OptionsConfigurationScreen({
    super.key,
    required this.providerId,
    this.plan,
    this.service,
  }) : assert(plan != null || service != null, 'Either plan or service must be provided');

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OptionsConfigurationBloc()
        ..add(InitializeOptionsConfiguration(
          providerId: providerId,
          plan: plan,
          service: service,
        )),
      child: const _OptionsConfigurationView(),
    );
  }
}

class _OptionsConfigurationView extends StatefulWidget {
  const _OptionsConfigurationView();

  @override
  State<_OptionsConfigurationView> createState() => _OptionsConfigurationViewState();
}

class _OptionsConfigurationViewState extends State<_OptionsConfigurationView> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<OptionsConfigurationBloc, OptionsConfigurationState>(
          builder: (context, state) {
            if (state is OptionsConfigurationInitial || (state.originalPlan == null && state.originalService == null)) {
              return const Text('Configure Options');
            }
            return Text('Configure: ${state.itemName}');
          },
        ),
        elevation: 1,
      ),
      body: BlocConsumer<OptionsConfigurationBloc, OptionsConfigurationState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            // Clear the error message in the BLoC after showing it
            // This requires an event or a flag in copyWith in the BLoC
            // For now, the BLoC's copyWith has 'clearErrorMessage'
          }
          if (state is OptionsConfigurationConfirmed) {
            // Navigate to the next screen (e.g., Booking Summary or Cart)
            // You'll need to define this route and screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Configuration Confirmed! Total: ${state.totalPrice.toStringAsFixed(2)}'),
                backgroundColor: Colors.green,
              ),
            );
            // Example: Navigator.pushNamed(context, '/bookingSummary', arguments: state);
            print('Configuration Confirmed. Data to pass: $state');
          }
        },
        builder: (context, state) {
          if (state is OptionsConfigurationInitial || state.isLoading && (state.originalPlan == null && state.originalService == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.originalPlan == null && state.originalService == null) {
             // This case should ideally be handled by the initial loading or an error state
             // if InitializeOptionsConfiguration fails to provide a plan/service.
            return const Center(child: Text("No item to configure. Please go back."));
          }


          final options = state.optionsDefinition;

          // Update notes controller if state changes
          if (_notesController.text != (state.notes ?? '')) {
             _notesController.text = state.notes ?? '';
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  state.itemName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Base Price: ${state.basePrice.toStringAsFixed(2)} ${state.originalPlan?.currency ?? state.originalService?.currency}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Dynamically build UI based on optionsDefinition
                if (options != null) ..._buildDynamicOptions(context, state, options),

                const SizedBox(height: 20),
                const Divider(),
                _buildPriceSummary(context, state),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: state.canConfirm ? Theme.of(context).primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: state.canConfirm
                      ? () => context.read<OptionsConfigurationBloc>().add(const ConfirmConfiguration())
                      : null,
                  child: Text(state.isLoading ? 'Processing...' : 'Confirm Options'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDynamicOptions(BuildContext context, OptionsConfigurationState state, Map<String, dynamic> options) {
    final List<Widget> widgets = [];

    // Date Selection
    if (options['allowDateSelection'] == true) {
      widgets.add(
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Select Date'),
          subtitle: Text(state.selectedDate != null ? DateFormat.yMMMd().format(state.selectedDate!) : 'Not selected'),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: state.selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null && picked != state.selectedDate) {
              context.read<OptionsConfigurationBloc>().add(DateSelected(selectedDate: picked));
            }
          },
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    // Time Selection
    if (options['allowTimeSelection'] == true) {
      // Example: Using ChoiceChips for predefined slots
      final List<String>? availableSlots = (options['availableTimeSlots'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      if (availableSlots != null && availableSlots.isNotEmpty) {
        widgets.add(const Text('Select Time Slot:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
        widgets.add(Wrap(
          spacing: 8.0,
          children: availableSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: state.selectedTime == slot,
              onSelected: (bool selected) {
                if (selected) {
                  context.read<OptionsConfigurationBloc>().add(TimeSelected(selectedTime: slot));
                }
              },
            );
          }).toList(),
        ));
      } else { // Fallback for simple time preference or if no slots defined
         widgets.add(
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Select Time'),
              subtitle: Text(state.selectedTime ?? 'Not selected'),
              // TODO: Implement a more generic time picker or selection method
              onTap: () {
                // Example: show a dialog with time options or a text field
                // For now, dispatching a placeholder if you want to test
                // context.read<OptionsConfigurationBloc>().add(const TimeSelected(selectedTime: "Morning"));
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Time selection UI placeholder")));
              },
            )
         );
      }
      widgets.add(const SizedBox(height: 10));
    }

    // Quantity Selection
    if (options['allowQuantitySelection'] == true) {
      final qtyDetails = options['quantityDetails'] as Map<String, dynamic>?;
      final String qtyLabel = qtyDetails?['label'] as String? ?? 'Quantity';
      final int minQty = (qtyDetails?['min'] as num?)?.toInt() ?? 1;
      final int maxQty = (qtyDetails?['max'] as num?)?.toInt() ?? 100; // Default max

      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$qtyLabel:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: state.quantity > minQty
                    ? () => context.read<OptionsConfigurationBloc>().add(QuantityChanged(quantity: state.quantity - 1))
                    : null,
              ),
              Text('${state.quantity}', style: const TextStyle(fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: state.quantity < maxQty
                    ? () => context.read<OptionsConfigurationBloc>().add(QuantityChanged(quantity: state.quantity + 1))
                    : null,
              ),
            ],
          ),
        ],
      ));
      widgets.add(const SizedBox(height: 10));
    }

    // Add-on Selection
    if (options['availableAddOns'] is List && (options['availableAddOns'] as List).isNotEmpty) {
      widgets.add(const Text('Available Add-ons:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
      final addOns = options['availableAddOns'] as List<dynamic>;
      for (var addOnData in addOns) {
        if (addOnData is Map<String, dynamic>) {
          final String id = addOnData['id'] as String? ?? '';
          final String name = addOnData['name'] as String? ?? 'Unnamed Add-on';
          final double price = (addOnData['price'] as num?)?.toDouble() ?? 0.0;
          final bool currentSelection = state.selectedAddOns[id] ?? (addOnData['defaultSelected'] as bool? ?? false);

          widgets.add(
            CheckboxListTile(
              title: Text('$name (+${price.toStringAsFixed(2)})'),
              value: currentSelection,
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  context.read<OptionsConfigurationBloc>().add(AddOnToggled(addOnId: id, isSelected: newValue, addOnPrice: price));
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }
      }
      widgets.add(const SizedBox(height: 10));
    }

    // Notes Field
    final notesPrompt = options['customizableNotes'];
    if (notesPrompt != null && (notesPrompt is bool && notesPrompt == true || notesPrompt is String)) {
      widgets.add(TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: notesPrompt is String && notesPrompt.isNotEmpty ? notesPrompt : 'Additional Notes',
          hintText: 'Any specific requests or instructions?',
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        onChanged: (value) {
          // Debounce or on unfocus might be better for performance
          context.read<OptionsConfigurationBloc>().add(NotesUpdated(notes: value));
        },
      ));
      widgets.add(const SizedBox(height: 10));
    }

    return widgets;
  }

  Widget _buildPriceSummary(BuildContext context, OptionsConfigurationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Base (${state.basePrice.toStringAsFixed(2)} x ${state.quantity}):'),
            Text('${(state.basePrice * state.quantity).toStringAsFixed(2)}'),
          ],
        ),
        if (state.addOnsPrice > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add-ons:'),
              Text(state.addOnsPrice.toStringAsFixed(2)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Price:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '${state.totalPrice.toStringAsFixed(2)} ${state.originalPlan?.currency ?? state.originalService?.currency}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ],
    );
  }
}
