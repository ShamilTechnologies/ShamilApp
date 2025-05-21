import * as admin from 'firebase-admin';

// Initialize Firebase admin
admin.initializeApp();

// Export all notification functions
export * from './notifications';

// Export all reservation-related functions
export * from './reservations/queue_management';
export * from './reservations/reminder_settings'; 