import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/queue_reservation_repository_impl.dart';
import 'package:shamil_mobile_app/shared/utils/logger.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({Key? key}) : super(key: key);

  @override
  _ReminderSettingsPageState createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  final Logger _logger = Logger('ReminderSettingsPage');
  final QueueReservationRepository _repository = QueueReservationRepository();

  bool _isLoading = true;
  bool _generalReminders = true;
  List<int> _reminderTimes = [60, 30]; // Default: 1 hour and 30 minutes
  bool _notifyOnQueueUpdates = true;
  int? _dailyReminderTime; // Null means no daily reminders

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _repository.getReminderSettings();

      if (result['success'] == true && result['settings'] != null) {
        final settings = result['settings'];

        setState(() {
          _generalReminders = settings['generalReminders'] ?? true;
          _notifyOnQueueUpdates = settings['notifyOnQueueUpdates'] ?? true;

          if (settings['reminderTimes'] != null) {
            _reminderTimes = List<int>.from(settings['reminderTimes']);
          }

          _dailyReminderTime = settings['dailyReminderTime'];
        });
      }
    } catch (e) {
      _logger.error('Error loading reminder settings', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _repository.updateReminderSettings(
        generalReminders: _generalReminders,
        reminderTimes: _reminderTimes,
        notifyOnQueueUpdates: _notifyOnQueueUpdates,
        dailyReminderTime: _dailyReminderTime,
      );

      if (result['success'] == true) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to save settings')),
        );
      }
    } catch (e) {
      _logger.error('Error saving reminder settings', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateReminderTime(int index, int newValue) {
    if (index >= 0 && index < _reminderTimes.length) {
      setState(() {
        _reminderTimes[index] = newValue;
        _hasChanges = true;
      });
    }
  }

  void _addReminderTime() {
    // Default to 15 minutes, or half of the smallest current reminder
    int newTime = 15;
    if (_reminderTimes.isNotEmpty) {
      _reminderTimes.sort();
      newTime = (_reminderTimes.first / 2).round();
      newTime = newTime < 5 ? 5 : newTime; // Minimum 5 minutes
    }

    setState(() {
      _reminderTimes.add(newTime);
      _hasChanges = true;
    });
  }

  void _removeReminderTime(int index) {
    if (index >= 0 && index < _reminderTimes.length) {
      setState(() {
        _reminderTimes.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsForm(),
    );
  }

  Widget _buildSettingsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General reminder toggle
          SwitchListTile(
            title: const Text('Enable Reservation Reminders'),
            subtitle:
                const Text('Get notified about your upcoming reservations'),
            value: _generalReminders,
            onChanged: (value) {
              setState(() {
                _generalReminders = value;
                _hasChanges = true;
              });
            },
          ),

          const Divider(),

          // Queue update toggle
          SwitchListTile(
            title: const Text('Queue Updates'),
            subtitle:
                const Text('Get notified about changes to your queue position'),
            value: _notifyOnQueueUpdates,
            onChanged: (value) {
              setState(() {
                _notifyOnQueueUpdates = value;
                _hasChanges = true;
              });
            },
          ),

          const Divider(),

          // Reminder times
          if (_generalReminders) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Times',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get reminders before your reservation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),

                  ..._reminderTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final minutes = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: minutes.toDouble(),
                              min: 5,
                              max: 180,
                              divisions: 35, // Every 5 minutes
                              label: '$minutes minutes',
                              onChanged: (value) {
                                _updateReminderTime(index, value.round());
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$minutes min',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeReminderTime(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Add new reminder button
                  if (_reminderTimes.length < 5) // Limit to 5 reminders
                    Center(
                      child: TextButton.icon(
                        onPressed: _addReminderTime,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Reminder'),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
          ],

          // Daily summary time picker
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Get a daily overview of your reservations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Send daily summary at:'),
                    const Spacer(),
                    DropdownButton<int?>(
                      value: _dailyReminderTime,
                      hint: const Text('No summary'),
                      onChanged: (value) {
                        setState(() {
                          _dailyReminderTime = value;
                          _hasChanges = true;
                        });
                      },
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No summary'),
                        ),
                        ...List.generate(24, (hour) {
                          final formattedHour = hour < 12
                              ? '$hour AM'
                              : hour == 12
                                  ? '12 PM'
                                  : '${hour - 12} PM';
                          return DropdownMenuItem<int?>(
                            value: hour,
                            child: Text(formattedHour),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
