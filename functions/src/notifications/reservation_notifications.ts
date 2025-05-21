import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { sendNotification, sendNotificationToUser } from './push_utilities';

interface ReservationData {
  id: string;
  userId: string;
  serviceProviderId: string;
  serviceName: string;
  appointmentTime: admin.firestore.Timestamp;
  status: string;
}

export const onReservationCreated = functions.firestore
  .document('reservations/{reservationId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const reservation = snap.data() as ReservationData;
    
    try {
      // Get user's OneSignal player ID
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(reservation.userId)
        .get();
      
      const playerId = userDoc.data()?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for user:', reservation.userId);
        return;
      }

      // Format appointment time
      const appointmentTime = reservation.appointmentTime.toDate();
      const formattedTime = appointmentTime.toLocaleString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        hour12: true
      });

      // Send notification using the utility function
      await sendNotification({
        playerIds: [playerId],
        title: 'Reservation Confirmed',
        message: `Your reservation for ${reservation.serviceName} is confirmed for ${formattedTime}`,
        data: {
          type: 'reservation',
          id: reservation.id,
          status: reservation.status
        }
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: reservation.userId,
        title: 'Reservation Confirmed',
        message: `Your reservation for ${reservation.serviceName} is confirmed for ${formattedTime}`,
        data: {
          type: 'reservation',
          id: reservation.id,
          status: reservation.status
        }
      });

      console.log('Reservation notification sent successfully');
    } catch (error) {
      console.error('Error sending reservation notification:', error);
    }
  });

export const onReservationUpdated = functions.firestore
  .document('reservations/{reservationId}')
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const newReservation = change.after.data() as ReservationData;
    const oldReservation = change.before.data() as ReservationData;

    // Only send notification if status changed
    if (newReservation.status === oldReservation.status) {
      return;
    }

    try {
      // Get user's OneSignal player ID
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(newReservation.userId)
        .get();
      
      const playerId = userDoc.data()?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for user:', newReservation.userId);
        return;
      }

      // Format appointment time
      const appointmentTime = newReservation.appointmentTime.toDate();
      const formattedTime = appointmentTime.toLocaleString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        hour12: true
      });

      let title = '';
      let message = '';

      switch (newReservation.status) {
        case 'confirmed':
          title = 'Reservation Confirmed';
          message = `Your reservation for ${newReservation.serviceName} is confirmed for ${formattedTime}`;
          break;
        case 'cancelled':
          title = 'Reservation Cancelled';
          message = `Your reservation for ${newReservation.serviceName} has been cancelled`;
          break;
        case 'completed':
          title = 'Reservation Completed';
          message = `Your reservation for ${newReservation.serviceName} has been completed`;
          break;
        case 'rescheduled':
          title = 'Reservation Rescheduled';
          message = `Your reservation for ${newReservation.serviceName} has been rescheduled to ${formattedTime}`;
          break;
        default:
          return; // Don't send notification for other status changes
      }

      // Send notification using the utility function
      await sendNotification({
        playerIds: [playerId],
        title: title,
        message: message,
        data: {
          type: 'reservation',
          id: newReservation.id,
          status: newReservation.status
        }
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: newReservation.userId,
        title: title,
        message: message,
        data: {
          type: 'reservation',
          id: newReservation.id,
          status: newReservation.status
        }
      });

      console.log('Reservation status update notification sent successfully');
    } catch (error) {
      console.error('Error sending reservation status update notification:', error);
    }
  });

export const sendReservationReminder = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('UTC')
  .onRun(async (context: functions.EventContext) => {
    const now = admin.firestore.Timestamp.now();
    const oneHourFromNow = new admin.firestore.Timestamp(
      now.seconds + 3600,
      now.nanoseconds
    );

    try {
      // Get all confirmed reservations happening in the next hour
      const reservationsSnapshot = await admin.firestore()
        .collection('reservations')
        .where('status', '==', 'confirmed')
        .where('appointmentTime', '>=', now)
        .where('appointmentTime', '<=', oneHourFromNow)
        .get();

      for (const doc of reservationsSnapshot.docs) {
        const reservation = doc.data() as ReservationData;
        
        // Get user's OneSignal player ID
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(reservation.userId)
          .get();
        
        const playerId = userDoc.data()?.oneSignalPlayerId;
        if (!playerId) {
          console.log('No OneSignal player ID found for user:', reservation.userId);
          continue;
        }

        // Format appointment time
        const appointmentTime = reservation.appointmentTime.toDate();
        const formattedTime = appointmentTime.toLocaleString('en-US', {
          hour: 'numeric',
          minute: 'numeric',
          hour12: true
        });

        // Send reminder notification
        await sendNotification({
          playerIds: [playerId],
          title: 'Upcoming Reservation',
          message: `Reminder: Your ${reservation.serviceName} appointment is at ${formattedTime}`,
          data: {
            type: 'reservation',
            id: reservation.id,
            status: reservation.status
          }
        });

        // Also send using userId for external notification targeting
        await sendNotificationToUser({
          userId: reservation.userId,
          title: 'Upcoming Reservation',
          message: `Reminder: Your ${reservation.serviceName} appointment is at ${formattedTime}`,
          data: {
            type: 'reservation',
            id: reservation.id,
            status: reservation.status
          }
        });

        console.log('Reservation reminder sent for:', reservation.id);
      }
    } catch (error) {
      console.error('Error sending reservation reminders:', error);
    }
  }); 