import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { sendNotification, sendNotificationToUser } from '../notifications/push_utilities';

// Define interfaces
interface ReminderSettings {
  userId: string;
  generalReminders: boolean;
  reminderTimes: number[]; // Minutes before reservation (e.g., [60, 30, 15])
  notifyOnQueueUpdates: boolean;
  dailyReminderTime?: number; // 0-23 hour of day for daily reminders
  updatedAt: admin.firestore.Timestamp;
}

interface ReservationData {
  id: string;
  userId: string;
  serviceProviderId: string;
  serviceName?: string;
  appointmentTime: admin.firestore.Timestamp;
  status: string;
  remindersSent?: string[]; // Array of reminder IDs that have been sent
  type: string;
}

// Cloud function to set/update reminder settings
export const updateReminderSettings = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to update reminder settings'
    );
  }

  const userId = context.auth.uid;
  const {
    generalReminders,
    reminderTimes,
    notifyOnQueueUpdates,
    dailyReminderTime
  } = data;

  // Input validation
  if (generalReminders === undefined) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing generalReminders field'
    );
  }

  // Basic validation of reminder times
  if (reminderTimes && !Array.isArray(reminderTimes)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'reminderTimes must be an array of numbers'
    );
  }

  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Create or update reminder settings
    const reminderSettingsRef = db.collection('reminderSettings').doc(userId);
    
    const reminderSettings: ReminderSettings = {
      userId,
      generalReminders: generalReminders ?? true,
      reminderTimes: reminderTimes ?? [60, 30], // Default to 1 hour and 30 minutes
      notifyOnQueueUpdates: notifyOnQueueUpdates ?? true,
      dailyReminderTime,
      updatedAt: now
    };
    
    await reminderSettingsRef.set(reminderSettings, { merge: true });
    
    return { success: true, message: 'Reminder settings updated successfully' };
  } catch (error) {
    console.error('Error updating reminder settings:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to update reminder settings'
    );
  }
});

// Get reminder settings for the current user
export const getReminderSettings = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to get reminder settings'
    );
  }

  const userId = context.auth.uid;

  try {
    const db = admin.firestore();
    
    // Get reminder settings
    const reminderSettingsDoc = await db.collection('reminderSettings').doc(userId).get();
    
    if (!reminderSettingsDoc.exists) {
      // Return default settings if none exist
      return {
        success: true,
        settings: {
          generalReminders: true,
          reminderTimes: [60, 30], // Default to 1 hour and 30 minutes
          notifyOnQueueUpdates: true
        }
      };
    }
    
    return { 
      success: true, 
      settings: reminderSettingsDoc.data() 
    };
  } catch (error) {
    console.error('Error getting reminder settings:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to get reminder settings'
    );
  }
});

// Scheduled function to send customized reminders based on user preferences
export const sendCustomizedReminders = functions.pubsub
  .schedule('*/5 * * * *') // Run every 5 minutes
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      
      // Get all users with reminder settings
      const reminderSettingsQuery = await db.collection('reminderSettings')
        .where('generalReminders', '==', true)
        .get();
      
      if (reminderSettingsQuery.empty) {
        console.log('No users with reminder settings found');
        return null;
      }
      
      // Process each user's reminder settings
      for (const settingsDoc of reminderSettingsQuery.docs) {
        const settings = settingsDoc.data() as ReminderSettings;
        const userId = settings.userId;
        
        // Skip if no reminder times are set
        if (!settings.reminderTimes || settings.reminderTimes.length === 0) {
          continue;
        }
        
        // Calculate timestamp ranges for each reminder time
        const reminderRanges = settings.reminderTimes.map(minutes => {
          const reminderTimeLower = new admin.firestore.Timestamp(
            now.seconds + (minutes * 60) - 150, // 2.5 minutes before
            now.nanoseconds
          );
          const reminderTimeUpper = new admin.firestore.Timestamp(
            now.seconds + (minutes * 60) + 150, // 2.5 minutes after
            now.nanoseconds
          );
          
          return {
            minutes,
            reminderTime: now.seconds + (minutes * 60),
            lower: reminderTimeLower,
            upper: reminderTimeUpper
          };
        });
        
        // Get all the user's upcoming reservations
        const reservationsQuery = await db.collection('reservations')
          .where('userId', '==', userId)
          .where('status', '==', 'confirmed')
          .where('appointmentTime', '>', now)
          .get();
        
        if (reservationsQuery.empty) {
          continue;
        }
        
        // Check each reservation against reminder times
        for (const reservationDoc of reservationsQuery.docs) {
          const reservation = reservationDoc.data() as ReservationData;
          const appointmentTime = reservation.appointmentTime;
          
          // Calculate time until appointment in seconds
          const secondsUntilAppointment = appointmentTime.seconds - now.seconds;
          
          // Check each reminder range
          for (const range of reminderRanges) {
            const minutesUntilAppointment = Math.floor(secondsUntilAppointment / 60);
            
            // Skip if this specific reminder was already sent
            const reminderKey = `${reservation.id}_${range.minutes}`;
            if (reservation.remindersSent && reservation.remindersSent.includes(reminderKey)) {
              continue;
            }
            
            // Check if it's time to send this reminder
            // We want to match when the minutesUntilAppointment is around the reminder time
            // (e.g., if reminder is set for 60 minutes, we check if it's between 57.5 and 62.5 minutes until appointment)
            if (Math.abs(minutesUntilAppointment - range.minutes) <= 2.5) {
              // Get user's OneSignal player ID
              const userDoc = await db.collection('users').doc(userId).get();
              const playerId = userDoc.data()?.oneSignalPlayerId;
              
              if (playerId) {
                // Format appointment time
                const appointmentTimeDate = appointmentTime.toDate();
                const formattedTime = appointmentTimeDate.toLocaleString('en-US', {
                  hour: 'numeric',
                  minute: 'numeric',
                  hour12: true
                });
                
                // Send notification
                await sendNotification({
                  playerIds: [playerId],
                  title: `Reminder: ${reservation.serviceName} in ${range.minutes} minutes`,
                  message: `Your appointment is at ${formattedTime}`,
                  data: {
                    type: 'reservation',
                    id: reservation.id,
                    status: reservation.status,
                    minutesUntil: range.minutes
                  }
                });
                
                // Also send using userId for external notification targeting
                await sendNotificationToUser({
                  userId,
                  title: `Reminder: ${reservation.serviceName} in ${range.minutes} minutes`,
                  message: `Your appointment is at ${formattedTime}`,
                  data: {
                    type: 'reservation',
                    id: reservation.id,
                    status: reservation.status,
                    minutesUntil: range.minutes
                  }
                });
                
                // Update reservation to mark this reminder as sent
                const remindersSent = reservation.remindersSent || [];
                remindersSent.push(reminderKey);
                
                await db.collection('reservations').doc(reservation.id).update({
                  remindersSent
                });
                
                console.log(`Sent ${range.minutes}-minute reminder for reservation ${reservation.id} to user ${userId}`);
              }
            }
          }
        }
      }
      
      return null;
    } catch (error) {
      console.error('Error sending customized reminders:', error);
      return null;
    }
  });

// Send a daily summary of upcoming reservations
export const sendDailySummary = functions.pubsub
  .schedule('0 * * * *') // Run once every hour
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      
      // Get current hour (UTC)
      const currentHour = new Date().getUTCHours();
      
      // Get users who want daily summaries at the current hour
      const reminderSettingsQuery = await db.collection('reminderSettings')
        .where('generalReminders', '==', true)
        .where('dailyReminderTime', '==', currentHour)
        .get();
      
      if (reminderSettingsQuery.empty) {
        console.log(`No users with daily reminders set for ${currentHour}:00 UTC`);
        return null;
      }
      
      // Process each user
      for (const settingsDoc of reminderSettingsQuery.docs) {
        const settings = settingsDoc.data() as ReminderSettings;
        const userId = settings.userId;
        
        // Define the time range for "today"
        const startOfDay = new Date();
        startOfDay.setUTCHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setUTCHours(23, 59, 59, 999);
        
        const startOfDayTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);
        const endOfDayTimestamp = admin.firestore.Timestamp.fromDate(endOfDay);
        
        // Get all the user's reservations for today
        const reservationsQuery = await db.collection('reservations')
          .where('userId', '==', userId)
          .where('status', '==', 'confirmed')
          .where('appointmentTime', '>=', startOfDayTimestamp)
          .where('appointmentTime', '<=', endOfDayTimestamp)
          .get();
        
        if (reservationsQuery.empty) {
          continue; // No reservations today
        }
        
        // Sort reservations by time
        const reservations = reservationsQuery.docs
          .map(doc => doc.data() as ReservationData)
          .sort((a, b) => a.appointmentTime.seconds - b.appointmentTime.seconds);
        
        // Construct summary message
        let summaryMessage = `You have ${reservations.length} reservation${reservations.length > 1 ? 's' : ''} today:`;
        
        // Add each reservation to the message
        for (const reservation of reservations) {
          const appointmentTime = reservation.appointmentTime.toDate();
          const formattedTime = appointmentTime.toLocaleString('en-US', {
            hour: 'numeric',
            minute: 'numeric',
            hour12: true
          });
          
          summaryMessage += `\n• ${reservation.serviceName || 'Service'} at ${formattedTime}`;
        }
        
        // Get user's OneSignal player ID
        const userDoc = await db.collection('users').doc(userId).get();
        const playerId = userDoc.data()?.oneSignalPlayerId;
        
        if (playerId) {
          // Send notification
          await sendNotification({
            playerIds: [playerId],
            title: 'Today\'s Reservations',
            message: summaryMessage,
            data: {
              type: 'daily_summary',
              count: reservations.length
            }
          });
          
          // Also send using userId for external notification targeting
          await sendNotificationToUser({
            userId,
            title: 'Today\'s Reservations',
            message: summaryMessage,
            data: {
              type: 'daily_summary',
              count: reservations.length
            }
          });
          
          console.log(`Sent daily summary to user ${userId}`);
        }
      }
      
      return null;
    } catch (error) {
      console.error('Error sending daily summaries:', error);
      return null;
    }
  }); 