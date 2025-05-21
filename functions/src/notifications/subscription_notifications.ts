import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { sendNotification, sendNotificationToUser } from './push_utilities';

interface Subscription {
  id: string;
  userId: string;
  planId: string;
  planName: string;
  status: 'active' | 'cancelled' | 'expired';
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  autoRenew: boolean;
}

interface UserData {
  name: string;
  oneSignalPlayerId?: string;
  email?: string;
}

export const onSubscriptionCreated = functions.firestore
  .document('subscriptions/{subscriptionId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const subscription = snap.data() as Subscription;
    
    try {
      // Get user's data
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(subscription.userId)
        .get();
      
      const userData = userDoc.data() as UserData;
      const playerId = userData?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for user:', subscription.userId);
        return;
      }

      // Format dates
      const startDate = subscription.startDate.toDate();
      const endDate = subscription.endDate.toDate();
      const formattedStartDate = startDate.toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      });
      const formattedEndDate = endDate.toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      });

      // Prepare notification data
      const notificationData = {
        type: 'subscription',
        id: subscription.id,
        status: subscription.status,
        planId: subscription.planId,
        planName: subscription.planName
      };

      // Send subscription confirmation notification
      await sendNotification({
        playerIds: [playerId],
        title: 'Subscription Activated',
        message: `Your ${subscription.planName} subscription is active from ${formattedStartDate} to ${formattedEndDate}`,
        data: notificationData
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: subscription.userId,
        title: 'Subscription Activated',
        message: `Your ${subscription.planName} subscription is active from ${formattedStartDate} to ${formattedEndDate}`,
        data: notificationData
      });

      console.log('Subscription confirmation notification sent successfully');
    } catch (error) {
      console.error('Error sending subscription confirmation notification:', error);
    }
  });

export const onSubscriptionUpdated = functions.firestore
  .document('subscriptions/{subscriptionId}')
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const newSubscription = change.after.data() as Subscription;
    const oldSubscription = change.before.data() as Subscription;

    // Only send notification if status changed
    if (newSubscription.status === oldSubscription.status) {
      return;
    }

    try {
      // Get user's data
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(newSubscription.userId)
        .get();
      
      const userData = userDoc.data() as UserData;
      const playerId = userData?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for user:', newSubscription.userId);
        return;
      }

      let title = '';
      let message = '';

      switch (newSubscription.status) {
        case 'cancelled':
          title = 'Subscription Cancelled';
          message = `Your ${newSubscription.planName} subscription has been cancelled`;
          break;
        case 'expired':
          title = 'Subscription Expired';
          message = `Your ${newSubscription.planName} subscription has expired`;
          break;
        default:
          return; // Don't send notification for other status changes
      }

      // Prepare notification data
      const notificationData = {
        type: 'subscription',
        id: newSubscription.id,
        status: newSubscription.status,
        planId: newSubscription.planId,
        planName: newSubscription.planName
      };

      // Send subscription status update notification
      await sendNotification({
        playerIds: [playerId],
        title: title,
        message: message,
        data: notificationData
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: newSubscription.userId,
        title: title,
        message: message,
        data: notificationData
      });

      console.log('Subscription status update notification sent successfully');
    } catch (error) {
      console.error('Error sending subscription status update notification:', error);
    }
  });

export const sendSubscriptionExpiryReminder = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context: functions.EventContext) => {
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = new admin.firestore.Timestamp(
      now.seconds + (3 * 24 * 3600),
      now.nanoseconds
    );

    try {
      // Get all active subscriptions expiring in the next 3 days
      const subscriptionsSnapshot = await admin.firestore()
        .collection('subscriptions')
        .where('status', '==', 'active')
        .where('endDate', '>=', now)
        .where('endDate', '<=', threeDaysFromNow)
        .get();

      for (const doc of subscriptionsSnapshot.docs) {
        const subscription = doc.data() as Subscription;
        
        // Get user's data
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(subscription.userId)
          .get();
        
        const userData = userDoc.data() as UserData;
        const playerId = userData?.oneSignalPlayerId;
        if (!playerId) {
          console.log('No OneSignal player ID found for user:', subscription.userId);
          continue;
        }

        // Calculate days until expiry
        const endDate = subscription.endDate.toDate();
        const daysUntilExpiry = Math.ceil((endDate.getTime() - now.toDate().getTime()) / (1000 * 60 * 60 * 24));

        // Prepare notification data
        const notificationData = {
          type: 'subscription',
          id: subscription.id,
          status: subscription.status,
          planId: subscription.planId,
          planName: subscription.planName,
          daysUntilExpiry
        };

        // Create message
        const message = `Your ${subscription.planName} subscription will expire in ${daysUntilExpiry} day${daysUntilExpiry === 1 ? '' : 's'}`;

        // Send expiry reminder notification
        await sendNotification({
          playerIds: [playerId],
          title: 'Subscription Expiring Soon',
          message: message,
          data: notificationData
        });

        // Also send using userId for external notification targeting
        await sendNotificationToUser({
          userId: subscription.userId,
          title: 'Subscription Expiring Soon',
          message: message,
          data: notificationData
        });

        console.log('Subscription expiry reminder sent for:', subscription.id);
      }
    } catch (error) {
      console.error('Error sending subscription expiry reminders:', error);
    }
  }); 