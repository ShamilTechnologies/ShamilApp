import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/queue_reservation_repository_impl.dart';
import 'package:shamil_mobile_app/shared/utils/logger.dart';

class QueueReservationPage extends StatefulWidget {
  final String providerId;
  final String? governorateId;
  final String? serviceId;
  final String? serviceName;
  final String? queueReservationId;

  const QueueReservationPage({
    Key? key,
    required this.providerId,
    this.governorateId,
    this.serviceId,
    this.serviceName,
    this.queueReservationId,
  }) : super(key: key);

  @override
  _QueueReservationPageState createState() => _QueueReservationPageState();
}

class _QueueReservationPageState extends State<QueueReservationPage> {
  final Logger _logger = Logger('QueueReservationPage');
  final QueueReservationRepository _repository = QueueReservationRepository();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedHour;

  String? _queueReservationId;
  int? _queuePosition;
  DateTime? _estimatedEntryTime;
  String _status = 'initial'; // 'initial', 'joining', 'in_queue', 'error'
  String? _errorMessage;

  Timer? _refreshTimer;
  final TextEditingController _notesController = TextEditingController();

  List<AttendeeModel> _attendees = [];

  @override
  void initState() {
    super.initState();
    _initializeAttendees();

    // If a queueReservationId is provided, load existing queue data
    if (widget.queueReservationId != null) {
      _queueReservationId = widget.queueReservationId;
      _status = 'in_queue';
      _checkQueueStatus();
      _startStatusRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeAttendees() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final userName = user?.displayName ?? 'User';

    if (userId != null) {
      setState(() {
        _attendees = [
          AttendeeModel(
            userId: userId,
            name: userName,
            type: 'primary',
            status: 'confirmed',
            paymentStatus: PaymentStatus.pending,
            isHost: true,
          ),
        ];
      });
    }
  }

  Future<void> _joinQueue() async {
    if (_selectedHour == null) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Please select a preferred time.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      setState(() {
        _status = 'error';
        _errorMessage = 'User not authenticated.';
      });
      return;
    }

    setState(() {
      _status = 'joining';
    });

    try {
      final result = await _repository.joinQueue(
        userId: userId,
        providerId: widget.providerId,
        governorateId: widget.governorateId,
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
        attendees: _attendees,
        preferredDate: _selectedDate,
        preferredHour: _selectedHour!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (result['success'] == true) {
        setState(() {
          _status = 'in_queue';
          _queueReservationId = result['queueReservationId'];
          _queuePosition = result['queuePosition'];

          if (result['estimatedEntryTime'] != null) {
            // Handle Firestore timestamp format
            final timestamp = result['estimatedEntryTime'];
            if (timestamp is Map && timestamp['_seconds'] != null) {
              _estimatedEntryTime = DateTime.fromMillisecondsSinceEpoch(
                  (timestamp['_seconds'] * 1000).toInt());
            } else {
              // Handle ISO string or other format
              _estimatedEntryTime = DateTime.parse(timestamp.toString());
            }
          }
        });

        // Start periodic queue status check
        _startStatusRefresh();
      } else {
        setState(() {
          _status = 'error';
          _errorMessage = result['error'] ?? 'Failed to join the queue.';
        });
      }
    } catch (e) {
      _logger.error('Error joining queue', e);
      setState(() {
        _status = 'error';
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  void _startStatusRefresh() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Start a new timer to check status every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkQueueStatus();
    });
  }

  Future<void> _checkQueueStatus() async {
    if (_queueReservationId == null) return;

    try {
      final result = await _repository.checkQueueStatus(
        queueReservationId: _queueReservationId!,
      );

      if (result['success'] == true) {
        setState(() {
          _queuePosition = result['queuePosition'];

          // Handle people ahead count
          final peopleAhead = result['peopleAhead'];
          if (peopleAhead != null && peopleAhead < _queuePosition!) {
            _queuePosition = peopleAhead + 1;
          }

          if (result['estimatedEntryTime'] != null) {
            // Handle Firestore timestamp format
            final timestamp = result['estimatedEntryTime'];
            if (timestamp is Map && timestamp['_seconds'] != null) {
              _estimatedEntryTime = DateTime.fromMillisecondsSinceEpoch(
                  (timestamp['_seconds'] * 1000).toInt());
            } else {
              // Handle ISO string or other format
              _estimatedEntryTime = DateTime.parse(timestamp.toString());
            }
          }

          // Check if our status has changed
          final status = result['status'];
          if (status == 'processing') {
            // It's our turn!
            _showYourTurnDialog();
          } else if (status == 'completed' ||
              status == 'cancelled' ||
              status == 'no_show') {
            // Queue entry is no longer active
            _refreshTimer?.cancel();
            _status = 'completed';
          }
        });
      }
    } catch (e) {
      _logger.error('Error checking queue status', e);
      // Don't update UI for status check errors, just log them
    }
  }

  Future<void> _leaveQueue() async {
    if (_queueReservationId == null) return;

    try {
      final result = await _repository.leaveQueue(
        queueReservationId: _queueReservationId!,
      );

      if (result['success'] == true) {
        _refreshTimer?.cancel();
        setState(() {
          _status = 'initial';
          _queueReservationId = null;
          _queuePosition = null;
          _estimatedEntryTime = null;
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the queue')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Failed to leave the queue')),
        );
      }
    } catch (e) {
      _logger.error('Error leaving queue', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  void _showYourTurnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('It\'s Your Turn!'),
        content: const Text(
          'Your turn has arrived! Please proceed to the service provider.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName != null
            ? 'Queue for ${widget.serviceName}'
            : 'Join Queue'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case 'initial':
        return _buildInitialView();
      case 'joining':
        return _buildLoadingView('Joining queue...');
      case 'in_queue':
        return _buildQueueStatusView();
      case 'error':
        return _buildErrorView();
      default:
        return _buildInitialView();
    }
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date & Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Date selection
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),

                  // Hour selection
                  ListTile(
                    title: const Text('Preferred Hour'),
                    subtitle: _selectedHour != null
                        ? Text(_selectedHour!.format(context))
                        : const Text('Select a time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedHour ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedHour = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Any special requests or information',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Join queue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joinQueue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Join Queue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildQueueStatusView() {
    // Calculate time remaining
    String timeRemaining = '';
    if (_estimatedEntryTime != null) {
      final now = DateTime.now();
      if (_estimatedEntryTime!.isAfter(now)) {
        final difference = _estimatedEntryTime!.difference(now);

        if (difference.inHours > 0) {
          timeRemaining =
              '${difference.inHours}h ${difference.inMinutes % 60}m';
        } else {
          timeRemaining = '${difference.inMinutes}m';
        }
      } else {
        timeRemaining = 'Any moment now';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 72,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are in the queue',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Position indicator
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${_queuePosition ?? "?"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estimated time
                  if (_estimatedEntryTime != null) ...[
                    Text(
                      'Estimated Time',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('h:mm a').format(_estimatedEntryTime!),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time remaining: $timeRemaining',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Information card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat.yMMMMd().format(_selectedDate)),
                  ),

                  // Time
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Preferred Time'),
                    subtitle:
                        Text(_selectedHour?.format(context) ?? 'Not specified'),
                  ),

                  // Notes if any
                  if (_notesController.text.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.note),
                      title: const Text('Notes'),
                      subtitle: Text(_notesController.text),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Leave queue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave Queue?'),
                    content: const Text(
                      'Are you sure you want to leave the queue? You will lose your position.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _leaveQueue();
                        },
                        child: const Text('Leave Queue'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
              ),
              child: const Text('Leave Queue'),
            ),
          ),

          const SizedBox(height: 8),

          // Refresh status button
          TextButton.icon(
            onPressed: _checkQueueStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _status = 'initial';
                  _errorMessage = null;
                });
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
