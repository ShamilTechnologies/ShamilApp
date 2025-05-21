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
exports.sendReservationReminder = exports.onReservationUpdated = exports.onReservationCreated = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const push_utilities_1 = require("./push_utilities");
exports.onReservationCreated = functions.firestore
    .document('reservations/{reservationId}')
    .onCreate(async (snap, context) => {
    var _a;
    const reservation = snap.data();
    try {
        // Get user's OneSignal player ID
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(reservation.userId)
            .get();
        const playerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
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
        await (0, push_utilities_1.sendNotificationToUser)({
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
    }
    catch (error) {
        console.error('Error sending reservation notification:', error);
    }
});
exports.onReservationUpdated = functions.firestore
    .document('reservations/{reservationId}')
    .onUpdate(async (change, context) => {
    var _a;
    const newReservation = change.after.data();
    const oldReservation = change.before.data();
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
        const playerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
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
        await (0, push_utilities_1.sendNotification)({
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
        await (0, push_utilities_1.sendNotificationToUser)({
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
    }
    catch (error) {
        console.error('Error sending reservation status update notification:', error);
    }
});
exports.sendReservationReminder = functions.pubsub
    .schedule('0 * * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
    var _a;
    const now = admin.firestore.Timestamp.now();
    const oneHourFromNow = new admin.firestore.Timestamp(now.seconds + 3600, now.nanoseconds);
    try {
        // Get all confirmed reservations happening in the next hour
        const reservationsSnapshot = await admin.firestore()
            .collection('reservations')
            .where('status', '==', 'confirmed')
            .where('appointmentTime', '>=', now)
            .where('appointmentTime', '<=', oneHourFromNow)
            .get();
        for (const doc of reservationsSnapshot.docs) {
            const reservation = doc.data();
            // Get user's OneSignal player ID
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(reservation.userId)
                .get();
            const playerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
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
            await (0, push_utilities_1.sendNotification)({
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
            await (0, push_utilities_1.sendNotificationToUser)({
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
    }
    catch (error) {
        console.error('Error sending reservation reminders:', error);
    }
});
//# sourceMappingURL=reservation_notifications.js.map