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
exports.sendSubscriptionExpiryReminder = exports.onSubscriptionUpdated = exports.onSubscriptionCreated = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const push_utilities_1 = require("./push_utilities");
exports.onSubscriptionCreated = functions.firestore
    .document('subscriptions/{subscriptionId}')
    .onCreate(async (snap, context) => {
    const subscription = snap.data();
    try {
        // Get user's data
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(subscription.userId)
            .get();
        const userData = userDoc.data();
        const playerId = userData === null || userData === void 0 ? void 0 : userData.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
            playerIds: [playerId],
            title: 'Subscription Activated',
            message: `Your ${subscription.planName} subscription is active from ${formattedStartDate} to ${formattedEndDate}`,
            data: notificationData
        });
        // Also send using userId for external notification targeting
        await (0, push_utilities_1.sendNotificationToUser)({
            userId: subscription.userId,
            title: 'Subscription Activated',
            message: `Your ${subscription.planName} subscription is active from ${formattedStartDate} to ${formattedEndDate}`,
            data: notificationData
        });
        console.log('Subscription confirmation notification sent successfully');
    }
    catch (error) {
        console.error('Error sending subscription confirmation notification:', error);
    }
});
exports.onSubscriptionUpdated = functions.firestore
    .document('subscriptions/{subscriptionId}')
    .onUpdate(async (change, context) => {
    const newSubscription = change.after.data();
    const oldSubscription = change.before.data();
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
        const userData = userDoc.data();
        const playerId = userData === null || userData === void 0 ? void 0 : userData.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
            playerIds: [playerId],
            title: title,
            message: message,
            data: notificationData
        });
        // Also send using userId for external notification targeting
        await (0, push_utilities_1.sendNotificationToUser)({
            userId: newSubscription.userId,
            title: title,
            message: message,
            data: notificationData
        });
        console.log('Subscription status update notification sent successfully');
    }
    catch (error) {
        console.error('Error sending subscription status update notification:', error);
    }
});
exports.sendSubscriptionExpiryReminder = functions.pubsub
    .schedule('0 0 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = new admin.firestore.Timestamp(now.seconds + (3 * 24 * 3600), now.nanoseconds);
    try {
        // Get all active subscriptions expiring in the next 3 days
        const subscriptionsSnapshot = await admin.firestore()
            .collection('subscriptions')
            .where('status', '==', 'active')
            .where('endDate', '>=', now)
            .where('endDate', '<=', threeDaysFromNow)
            .get();
        for (const doc of subscriptionsSnapshot.docs) {
            const subscription = doc.data();
            // Get user's data
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(subscription.userId)
                .get();
            const userData = userDoc.data();
            const playerId = userData === null || userData === void 0 ? void 0 : userData.oneSignalPlayerId;
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
            await (0, push_utilities_1.sendNotification)({
                playerIds: [playerId],
                title: 'Subscription Expiring Soon',
                message: message,
                data: notificationData
            });
            // Also send using userId for external notification targeting
            await (0, push_utilities_1.sendNotificationToUser)({
                userId: subscription.userId,
                title: 'Subscription Expiring Soon',
                message: message,
                data: notificationData
            });
            console.log('Subscription expiry reminder sent for:', subscription.id);
        }
    }
    catch (error) {
        console.error('Error sending subscription expiry reminders:', error);
    }
});
//# sourceMappingURL=subscription_notifications.js.map