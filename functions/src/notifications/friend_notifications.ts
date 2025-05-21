import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { sendNotification, sendNotificationToUser } from './push_utilities';

interface FriendRequest {
  id: string;
  senderId: string;
  receiverId: string;
  status: 'pending' | 'accepted' | 'rejected';
  timestamp: admin.firestore.Timestamp;
}

interface UserData {
  name: string;
  oneSignalPlayerId?: string;
  profilePicUrl?: string;
}

export const onFriendRequestCreated = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const friendRequest = snap.data() as FriendRequest;
    
    try {
      // Get sender's data
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(friendRequest.senderId)
        .get();
      
      const senderData = senderDoc.data() as UserData;
      if (!senderData) {
        console.log('Sender data not found:', friendRequest.senderId);
        return;
      }

      // Get receiver's OneSignal player ID
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(friendRequest.receiverId)
        .get();
      
      const receiverData = receiverDoc.data() as UserData;
      const playerId = receiverData?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for receiver:', friendRequest.receiverId);
        return;
      }

      // Prepare notification data
      const notificationData = {
        type: 'friend',
        id: friendRequest.id,
        action: 'request',
        senderId: friendRequest.senderId,
        senderName: senderData.name,
        senderImage: senderData.profilePicUrl
      };

      // Send friend request notification
      await sendNotification({
        playerIds: [playerId],
        title: 'New Friend Request',
        message: `${senderData.name} sent you a friend request`,
        data: notificationData,
        bigPicture: senderData.profilePicUrl
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: friendRequest.receiverId,
        title: 'New Friend Request',
        message: `${senderData.name} sent you a friend request`,
        data: notificationData,
        bigPicture: senderData.profilePicUrl
      });

      console.log('Friend request notification sent successfully');
    } catch (error) {
      console.error('Error sending friend request notification:', error);
    }
  });

export const onFriendRequestUpdated = functions.firestore
  .document('friendRequests/{requestId}')
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const newRequest = change.after.data() as FriendRequest;
    const oldRequest = change.before.data() as FriendRequest;

    // Only send notification if status changed to accepted
    if (newRequest.status !== 'accepted' || oldRequest.status === 'accepted') {
      return;
    }

    try {
      // Get receiver's data (now the friend)
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(newRequest.receiverId)
        .get();
      
      const receiverData = receiverDoc.data() as UserData;
      if (!receiverData) {
        console.log('Receiver data not found:', newRequest.receiverId);
        return;
      }

      // Get sender's OneSignal player ID
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(newRequest.senderId)
        .get();
      
      const senderData = senderDoc.data() as UserData;
      const playerId = senderData?.oneSignalPlayerId;
      if (!playerId) {
        console.log('No OneSignal player ID found for sender:', newRequest.senderId);
        return;
      }

      // Prepare notification data
      const notificationData = {
        type: 'friend',
        id: newRequest.id,
        action: 'accepted',
        friendId: newRequest.receiverId,
        friendName: receiverData.name,
        friendImage: receiverData.profilePicUrl
      };

      // Send friend request accepted notification
      await sendNotification({
        playerIds: [playerId],
        title: 'Friend Request Accepted',
        message: `${receiverData.name} accepted your friend request`,
        data: notificationData,
        bigPicture: receiverData.profilePicUrl
      });

      // Also send using userId for external notification targeting
      await sendNotificationToUser({
        userId: newRequest.senderId,
        title: 'Friend Request Accepted',
        message: `${receiverData.name} accepted your friend request`,
        data: notificationData,
        bigPicture: receiverData.profilePicUrl
      });

      console.log('Friend request accepted notification sent successfully');
    } catch (error) {
      console.error('Error sending friend request accepted notification:', error);
    }
  });

export const onFriendActivity = functions.firestore
  .document('userActivities/{activityId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const activity = snap.data();
    
    // Only handle certain types of activities
    if (!['reservation', 'review', 'checkin'].includes(activity.type)) {
      return;
    }

    try {
      // Get the user's friends
      const friendsSnapshot = await admin.firestore()
        .collection('friends')
        .where('userId', '==', activity.userId)
        .get();

      if (friendsSnapshot.empty) {
        return;
      }

      // Get user's data
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(activity.userId)
        .get();
      
      const userData = userDoc.data() as UserData;
      if (!userData) {
        console.log('User data not found:', activity.userId);
        return;
      }

      // Get all friend's OneSignal player IDs
      const friendIds = friendsSnapshot.docs.map(doc => doc.data().friendId);
      const friendsDocs = await Promise.all(
        friendIds.map(id => 
          admin.firestore()
            .collection('users')
            .doc(id)
            .get()
        )
      );

      const playerIds = friendsDocs
        .map(doc => (doc.data() as UserData)?.oneSignalPlayerId)
        .filter(id => id != null) as string[];

      if (playerIds.length === 0) {
        return;
      }

      // Create activity message
      let message = '';
      switch (activity.type) {
        case 'reservation':
          message = `${userData.name} made a new reservation`;
          break;
        case 'review':
          message = `${userData.name} wrote a new review`;
          break;
        case 'checkin':
          message = `${userData.name} checked in at a new place`;
          break;
      }

      // Prepare notification data
      const notificationData = {
        type: 'friend',
        action: 'activity',
        activityType: activity.type,
        userId: activity.userId,
        userName: userData.name,
        userImage: userData.profilePicUrl,
        activityId: activity.id
      };

      // Send activity notification to all friends
      await sendNotification({
        playerIds: playerIds,
        title: 'Friend Activity',
        message: message,
        data: notificationData,
        bigPicture: userData.profilePicUrl
      });

      // Also send to each friend individually by userId for better targeting
      await Promise.all(
        friendIds.map(friendId =>
          sendNotificationToUser({
            userId: friendId,
            title: 'Friend Activity',
            message: message,
            data: notificationData,
            bigPicture: userData.profilePicUrl
          })
        )
      );

      console.log('Friend activity notification sent successfully');
    } catch (error) {
      console.error('Error sending friend activity notification:', error);
    }
  }); 