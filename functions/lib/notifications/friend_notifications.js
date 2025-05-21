"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFriendActivity = exports.onFriendRequestUpdated = exports.onFriendRequestCreated = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const push_utilities_1 = require("./push_utilities");
exports.onFriendRequestCreated = functions.firestore
    .document('friendRequests/{requestId}')
    .onCreate(async (snap, context) => {
    const friendRequest = snap.data();
    try {
        // Get sender's data
        const senderDoc = await admin.firestore()
            .collection('users')
            .doc(friendRequest.senderId)
            .get();
        const senderData = senderDoc.data();
        if (!senderData) {
            console.log('Sender data not found:', friendRequest.senderId);
            return;
        }
        // Get receiver's OneSignal player ID
        const receiverDoc = await admin.firestore()
            .collection('users')
            .doc(friendRequest.receiverId)
            .get();
        const receiverData = receiverDoc.data();
        const playerId = receiverData === null || receiverData === void 0 ? void 0 : receiverData.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
            playerIds: [playerId],
            title: 'New Friend Request',
            message: `${senderData.name} sent you a friend request`,
            data: notificationData,
            bigPicture: senderData.profilePicUrl
        });
        // Also send using userId for external notification targeting
        await (0, push_utilities_1.sendNotificationToUser)({
            userId: friendRequest.receiverId,
            title: 'New Friend Request',
            message: `${senderData.name} sent you a friend request`,
            data: notificationData,
            bigPicture: senderData.profilePicUrl
        });
        console.log('Friend request notification sent successfully');
    }
    catch (error) {
        console.error('Error sending friend request notification:', error);
    }
});
exports.onFriendRequestUpdated = functions.firestore
    .document('friendRequests/{requestId}')
    .onUpdate(async (change, context) => {
    const newRequest = change.after.data();
    const oldRequest = change.before.data();
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
        const receiverData = receiverDoc.data();
        if (!receiverData) {
            console.log('Receiver data not found:', newRequest.receiverId);
            return;
        }
        // Get sender's OneSignal player ID
        const senderDoc = await admin.firestore()
            .collection('users')
            .doc(newRequest.senderId)
            .get();
        const senderData = senderDoc.data();
        const playerId = senderData === null || senderData === void 0 ? void 0 : senderData.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
            playerIds: [playerId],
            title: 'Friend Request Accepted',
            message: `${receiverData.name} accepted your friend request`,
            data: notificationData,
            bigPicture: receiverData.profilePicUrl
        });
        // Also send using userId for external notification targeting
        await (0, push_utilities_1.sendNotificationToUser)({
            userId: newRequest.senderId,
            title: 'Friend Request Accepted',
            message: `${receiverData.name} accepted your friend request`,
            data: notificationData,
            bigPicture: receiverData.profilePicUrl
        });
        console.log('Friend request accepted notification sent successfully');
    }
    catch (error) {
        console.error('Error sending friend request accepted notification:', error);
    }
});
exports.onFriendActivity = functions.firestore
    .document('userActivities/{activityId}')
    .onCreate(async (snap, context) => {
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
        const userData = userDoc.data();
        if (!userData) {
            console.log('User data not found:', activity.userId);
            return;
        }
        // Get all friend's OneSignal player IDs
        const friendIds = friendsSnapshot.docs.map(doc => doc.data().friendId);
        const friendsDocs = await Promise.all(friendIds.map(id => admin.firestore()
            .collection('users')
            .doc(id)
            .get()));
        const playerIds = friendsDocs
            .map(doc => { var _a; return (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId; })
            .filter(id => id != null);
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
        await (0, push_utilities_1.sendNotification)({
            playerIds: playerIds,
            title: 'Friend Activity',
            message: message,
            data: notificationData,
            bigPicture: userData.profilePicUrl
        });
        // Also send to each friend individually by userId for better targeting
        await Promise.all(friendIds.map(friendId => (0, push_utilities_1.sendNotificationToUser)({
            userId: friendId,
            title: 'Friend Activity',
            message: message,
            data: notificationData,
            bigPicture: userData.profilePicUrl
        })));
        console.log('Friend activity notification sent successfully');
    }
    catch (error) {
        console.error('Error sending friend activity notification:', error);
    }
});
//# sourceMappingURL=friend_notifications.js.map