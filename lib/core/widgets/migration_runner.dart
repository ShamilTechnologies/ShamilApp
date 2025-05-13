import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/options_configuration/repository/migration_helper.dart';

/// A widget that provides UI for running migration utilities.
/// This should only be used temporarily during the transition period.
class MigrationRunner extends StatefulWidget {
  const MigrationRunner({super.key});

  @override
  State<MigrationRunner> createState() => _MigrationRunnerState();
}

class _MigrationRunnerState extends State<MigrationRunner> {
  final MigrationHelper _migrationHelper = MigrationHelper();
  bool _isRunningReservationMigration = false;
  bool _isRunningSubscriptionMigration = false;
  String _reservationResults = '';
  String _subscriptionResults = '';

  Future<void> _migrateReservations() async {
    if (_isRunningReservationMigration) return;

    setState(() {
      _isRunningReservationMigration = true;
      _reservationResults = 'Migration in progress...';
    });

    try {
      await _migrationHelper.migrateReservationData();
      setState(() {
        _reservationResults = 'Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _reservationResults = 'Error during migration: $e';
      });
    } finally {
      setState(() {
        _isRunningReservationMigration = false;
      });
    }
  }

  Future<void> _migrateSubscriptions() async {
    if (_isRunningSubscriptionMigration) return;

    setState(() {
      _isRunningSubscriptionMigration = true;
      _subscriptionResults = 'Migration in progress...';
    });

    try {
      await _migrationHelper.migrateSubscriptionData();
      setState(() {
        _subscriptionResults = 'Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _subscriptionResults = 'Error during migration: $e';
      });
    } finally {
      setState(() {
        _isRunningSubscriptionMigration = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration Tools'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                color: Colors.amber,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'WARNING: This tool should only be used by developers during the transition to the new data structure. '
                    'Running these migrations multiple times could cause data duplication!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reservation migration
              const Text(
                'Reservation Migration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Migrates reservations from global collection to user subcollections',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isRunningReservationMigration
                    ? null
                    : _migrateReservations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isRunningReservationMigration
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Migrating...'),
                        ],
                      )
                    : const Text('Migrate Reservations'),
              ),
              const SizedBox(height: 8),
              if (_reservationResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_reservationResults),
                ),

              const SizedBox(height: 32),

              // Subscription migration
              const Text(
                'Subscription Migration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Migrates subscriptions from global collection to user subcollections',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isRunningSubscriptionMigration
                    ? null
                    : _migrateSubscriptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isRunningSubscriptionMigration
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Migrating...'),
                        ],
                      )
                    : const Text('Migrate Subscriptions'),
              ),
              const SizedBox(height: 8),
              if (_subscriptionResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_subscriptionResults),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
