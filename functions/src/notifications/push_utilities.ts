import * as functions from 'firebase-functions/v1';
import * as OneSignal from 'onesignal-node';

// Initialize OneSignal client
export const initializeOneSignal = (): OneSignal.Client => {
  return new OneSignal.Client(
    functions.config().onesignal.app_id,
    functions.config().onesignal.api_key
  );
};

// Encode a notification action button
export interface ActionButton {
  id: string;
  text: string;
  icon?: string;
}

// Helper function to create and send a notification through OneSignal API
export async function sendNotification({
  playerIds,
  title,
  message,
  data,
  actionButtons = [],
  bigPicture,
  url,
}: {
  playerIds: string[];
  title: string;
  message: string;
  data?: { [key: string]: any };
  actionButtons?: ActionButton[];
  bigPicture?: string;
  url?: string;
}): Promise<void> {
  try {
    if (!playerIds.length) {
      console.log('No player IDs to send to, skipping notification');
      return;
    }

    // Initialize OneSignal client
    const client = initializeOneSignal();

    // Prepare notification
    const notification: any = {
      include_player_ids: playerIds,
      headings: { en: title },
      contents: { en: message },
      data: data || {},
      app_url: url,
    };

    // Add buttons if provided
    if (actionButtons.length > 0) {
      notification.buttons = actionButtons.map(button => ({
        id: button.id,
        text: button.text,
        icon: button.icon,
      }));
    }

    // Add big picture if provided (for Android)
    if (bigPicture) {
      notification.big_picture = bigPicture;
      notification.large_icon = bigPicture;
    }

    // Send notification
    await client.createNotification(notification);
    console.log(`Notification sent successfully to ${playerIds.length} devices`);
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

// Helper to send a notification to a specific user by userId
export async function sendNotificationToUser({
  userId,
  title,
  message,
  data,
  actionButtons,
  bigPicture,
  url,
}: {
  userId: string;
  title: string;
  message: string;
  data?: { [key: string]: any };
  actionButtons?: ActionButton[];
  bigPicture?: string;
  url?: string;
}): Promise<void> {
  try {
    // Initialize OneSignal client
    const client = initializeOneSignal();

    // Create notification by external user ID
    const notification: any = {
      include_external_user_ids: [userId],
      headings: { en: title },
      contents: { en: message },
      data: data || {},
      app_url: url,
    };

    // Add buttons if provided
    if (actionButtons && actionButtons.length > 0) {
      notification.buttons = actionButtons.map(button => ({
        id: button.id,
        text: button.text,
        icon: button.icon,
      }));
    }

    // Add big picture if provided (for Android)
    if (bigPicture) {
      notification.big_picture = bigPicture;
      notification.large_icon = bigPicture;
    }

    // Send notification
    await client.createNotification(notification);
    console.log(`Notification sent successfully to user ${userId}`);
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
    throw error;
  }
}

// Helper to send a notification to all subscribed users
export async function sendNotificationToAll({
  title,
  message,
  data,
  segments = ['All'],
  actionButtons,
  bigPicture,
  url,
}: {
  title: string;
  message: string;
  data?: { [key: string]: any };
  segments?: string[];
  actionButtons?: ActionButton[];
  bigPicture?: string;
  url?: string;
}): Promise<void> {
  try {
    // Initialize OneSignal client
    const client = initializeOneSignal();

    // Create notification for segments
    const notification: any = {
      included_segments: segments,
      headings: { en: title },
      contents: { en: message },
      data: data || {},
      app_url: url,
    };

    // Add buttons if provided
    if (actionButtons && actionButtons.length > 0) {
      notification.buttons = actionButtons.map(button => ({
        id: button.id,
        text: button.text,
        icon: button.icon,
      }));
    }

    // Add big picture if provided (for Android)
    if (bigPicture) {
      notification.big_picture = bigPicture;
      notification.large_icon = bigPicture;
    }

    // Send notification
    await client.createNotification(notification);
    console.log(`Notification sent successfully to segments: ${segments.join(', ')}`);
  } catch (error) {
    console.error('Error sending notification to all:', error);
    throw error;
  }
} 