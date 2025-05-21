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
exports.initializeOneSignal = void 0;
exports.sendNotification = sendNotification;
exports.sendNotificationToUser = sendNotificationToUser;
exports.sendNotificationToAll = sendNotificationToAll;
const functions = __importStar(require("firebase-functions/v1"));
const OneSignal = __importStar(require("onesignal-node"));
// Initialize OneSignal client
const initializeOneSignal = () => {
    return new OneSignal.Client(functions.config().onesignal.app_id, functions.config().onesignal.api_key);
};
exports.initializeOneSignal = initializeOneSignal;
// Helper function to create and send a notification through OneSignal API
async function sendNotification({ playerIds, title, message, data, actionButtons = [], bigPicture, url, }) {
    try {
        if (!playerIds.length) {
            console.log('No player IDs to send to, skipping notification');
            return;
        }
        // Initialize OneSignal client
        const client = (0, exports.initializeOneSignal)();
        // Prepare notification
        const notification = {
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
    }
    catch (error) {
        console.error('Error sending notification:', error);
        throw error;
    }
}
// Helper to send a notification to a specific user by userId
async function sendNotificationToUser({ userId, title, message, data, actionButtons, bigPicture, url, }) {
    try {
        // Initialize OneSignal client
        const client = (0, exports.initializeOneSignal)();
        // Create notification by external user ID
        const notification = {
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
    }
    catch (error) {
        console.error(`Error sending notification to user ${userId}:`, error);
        throw error;
    }
}
// Helper to send a notification to all subscribed users
async function sendNotificationToAll({ title, message, data, segments = ['All'], actionButtons, bigPicture, url, }) {
    try {
        // Initialize OneSignal client
        const client = (0, exports.initializeOneSignal)();
        // Create notification for segments
        const notification = {
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
    }
    catch (error) {
        console.error('Error sending notification to all:', error);
        throw error;
    }
}
//# sourceMappingURL=push_utilities.js.map