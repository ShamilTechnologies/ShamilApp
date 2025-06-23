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
exports.getUserQueueHistory = exports.autoEnrollReservationsToQueue = exports.markNoShow = exports.completeQueueEntry = exports.processQueues = exports.leaveQueue = exports.checkQueueStatus = exports.joinQueue = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const push_utilities_1 = require("../notifications/push_utilities");
// Cloud function to join a queue
exports.joinQueue = functions.https.onCall(async (data, context) => {
    var _a;
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to join a queue');
    }
    const userId = context.auth.uid;
    const { providerId, governorateId, serviceId, preferredDate, preferredHour, attendees, notes } = data;
    // Input validation
    if (!providerId || !governorateId || !preferredDate || preferredHour === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields to join queue');
    }
    try {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        // Convert preferredDate string to Timestamp
        const dateObj = new Date(preferredDate);
        const preferredDateTimestamp = admin.firestore.Timestamp.fromDate(dateObj);
        // Get or create queue settings for this time slot
        const queueSettingsRef = db.collection('queueSettings').doc(`${providerId}_${governorateId}_${serviceId || 'general'}_${dateObj.toISOString().slice(0, 10)}_${preferredHour}`);
        // Use transaction to ensure atomic operations
        const result = await db.runTransaction(async (transaction) => {
            const queueSettingsDoc = await transaction.get(queueSettingsRef);
            let queueSettings;
            if (!queueSettingsDoc.exists) {
                // Create new queue settings if it doesn't exist
                const defaultProcessingRate = 10; // 10 minutes per person by default
                queueSettings = {
                    id: queueSettingsRef.id,
                    providerId,
                    governorateId,
                    serviceId,
                    date: preferredDateTimestamp,
                    hour: preferredHour,
                    maxCapacity: 50, // Default max capacity
                    currentPosition: 0,
                    processingRate: defaultProcessingRate,
                    isActive: true,
                    lastUpdated: now
                };
                transaction.set(queueSettingsRef, queueSettings);
            }
            else {
                queueSettings = queueSettingsDoc.data();
                // Check if queue is active
                if (!queueSettings.isActive) {
                    throw new functions.https.HttpsError('failed-precondition', 'This queue is no longer accepting new reservations');
                }
            }
            // Check if user is already in queue for this time slot
            const existingQueueQuery = await transaction.get(db.collection('queueReservations')
                .where('userId', '==', userId)
                .where('providerId', '==', providerId)
                .where('preferredDate', '==', preferredDateTimestamp)
                .where('preferredHour', '==', preferredHour)
                .where('status', 'in', ['waiting', 'processing']));
            if (!existingQueueQuery.empty) {
                throw new functions.https.HttpsError('already-exists', 'You are already in this queue');
            }
            // Calculate queue position and estimated entry time
            const nextPosition = queueSettings.currentPosition + 1;
            // Calculate estimated entry time: current time + (position * processing rate in minutes)
            const estimatedWaitMinutes = nextPosition * queueSettings.processingRate;
            const estimatedEntryTime = new admin.firestore.Timestamp(now.seconds + (estimatedWaitMinutes * 60), now.nanoseconds);
            // Get user information
            const userDoc = await transaction.get(db.collection('users').doc(userId));
            if (!userDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'User not found');
            }
            const userData = userDoc.data();
            // Create queue reservation
            const queueReservationRef = db.collection('queueReservations').doc();
            const queueReservation = {
                id: queueReservationRef.id,
                userId,
                userName: (userData === null || userData === void 0 ? void 0 : userData.name) || 'Unknown User',
                providerId,
                governorateId,
                serviceId,
                serviceName: data.serviceName,
                preferredDate: preferredDateTimestamp,
                preferredHour,
                attendees: attendees || [{
                        userId,
                        name: (userData === null || userData === void 0 ? void 0 : userData.name) || 'Unknown User',
                        type: 'primary',
                        status: 'confirmed',
                        paymentStatus: 'pending',
                        isHost: true
                    }],
                queuePosition: nextPosition,
                estimatedEntryTime,
                status: 'waiting',
                createdAt: now,
                notes,
                reminderSent: false
            };
            // Write queue reservation to Firestore
            transaction.set(queueReservationRef, queueReservation);
            // Update queue position counter
            transaction.update(queueSettingsRef, {
                currentPosition: nextPosition,
                lastUpdated: now
            });
            return {
                success: true,
                queuePosition: nextPosition,
                estimatedEntryTime,
                queueReservationId: queueReservationRef.id
            };
        });
        // Send confirmation notification
        try {
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(userId)
                .get();
            const playerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
            if (playerId) {
                // Format estimated entry time
                const entryTime = result.estimatedEntryTime.toDate();
                const formattedTime = entryTime.toLocaleString('en-US', {
                    hour: 'numeric',
                    minute: 'numeric',
                    hour12: true
                });
                // Send notification
                await (0, push_utilities_1.sendNotification)({
                    playerIds: [playerId],
                    title: 'Added to Queue',
                    message: `You are #${result.queuePosition} in line. Estimated entry time: ${formattedTime}`,
                    data: {
                        type: 'queue',
                        id: result.queueReservationId,
                        queuePosition: result.queuePosition
                    }
                });
                // Also send using userId for external notification targeting
                await (0, push_utilities_1.sendNotificationToUser)({
                    userId,
                    title: 'Added to Queue',
                    message: `You are #${result.queuePosition} in line. Estimated entry time: ${formattedTime}`,
                    data: {
                        type: 'queue',
                        id: result.queueReservationId,
                        queuePosition: result.queuePosition
                    }
                });
            }
        }
        catch (notifError) {
            console.error('Error sending queue notification:', notifError);
            // Continue even if notification fails
        }
        return result;
    }
    catch (error) {
        console.error('Error joining queue:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to join queue');
    }
});
// Cloud function to check queue status
exports.checkQueueStatus = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to check queue status');
    }
    const userId = context.auth.uid;
    const { queueReservationId } = data;
    // Input validation
    if (!queueReservationId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing queue reservation ID');
    }
    try {
        const db = admin.firestore();
        // Get queue reservation
        const queueReservationDoc = await db.collection('queueReservations').doc(queueReservationId).get();
        if (!queueReservationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Queue reservation not found');
        }
        const queueReservation = queueReservationDoc.data();
        // Check if this reservation belongs to the user
        if (queueReservation.userId !== userId) {
            throw new functions.https.HttpsError('permission-denied', 'You do not have permission to check this queue reservation');
        }
        // Get queue settings
        const queueSettingsId = `${queueReservation.providerId}_${queueReservation.governorateId}_${queueReservation.serviceId || 'general'}_${queueReservation.preferredDate.toDate().toISOString().slice(0, 10)}_${queueReservation.preferredHour}`;
        const queueSettingsDoc = await db.collection('queueSettings').doc(queueSettingsId).get();
        if (!queueSettingsDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Queue settings not found');
        }
        const queueSettings = queueSettingsDoc.data();
        // Get people ahead in queue
        const peopleAheadQuery = await db.collection('queueReservations')
            .where('providerId', '==', queueReservation.providerId)
            .where('governorateId', '==', queueReservation.governorateId)
            .where('preferredDate', '==', queueReservation.preferredDate)
            .where('preferredHour', '==', queueReservation.preferredHour)
            .where('queuePosition', '<', queueReservation.queuePosition)
            .where('status', 'in', ['waiting', 'processing'])
            .get();
        const peopleAhead = peopleAheadQuery.size;
        // Recalculate estimated entry time based on current conditions
        const now = admin.firestore.Timestamp.now();
        const estimatedWaitMinutes = peopleAhead * queueSettings.processingRate;
        const estimatedEntryTime = new admin.firestore.Timestamp(now.seconds + (estimatedWaitMinutes * 60), now.nanoseconds);
        // Update estimated entry time if it has changed significantly (> 5 minutes)
        if (queueReservation.estimatedEntryTime &&
            Math.abs(estimatedEntryTime.seconds - queueReservation.estimatedEntryTime.seconds) > 300) {
            await db.collection('queueReservations').doc(queueReservationId).update({
                estimatedEntryTime,
                updatedAt: now
            });
        }
        return {
            success: true,
            status: queueReservation.status,
            queuePosition: queueReservation.queuePosition,
            peopleAhead,
            estimatedEntryTime,
            queueActive: queueSettings.isActive
        };
    }
    catch (error) {
        console.error('Error checking queue status:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to check queue status');
    }
});
// Cloud function to leave queue
exports.leaveQueue = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to leave a queue');
    }
    const userId = context.auth.uid;
    const { queueReservationId } = data;
    // Input validation
    if (!queueReservationId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing queue reservation ID');
    }
    try {
        const db = admin.firestore();
        // Get queue reservation
        const queueReservationDoc = await db.collection('queueReservations').doc(queueReservationId).get();
        if (!queueReservationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Queue reservation not found');
        }
        const queueReservation = queueReservationDoc.data();
        // Check if this reservation belongs to the user
        if (queueReservation.userId !== userId) {
            throw new functions.https.HttpsError('permission-denied', 'You do not have permission to cancel this queue reservation');
        }
        // Check if already cancelled
        if (queueReservation.status === 'cancelled') {
            return { success: true, message: 'Queue reservation was already cancelled' };
        }
        // Update status to cancelled
        const now = admin.firestore.Timestamp.now();
        await db.collection('queueReservations').doc(queueReservationId).update({
            status: 'cancelled',
            updatedAt: now
        });
        return { success: true, message: 'Successfully left the queue' };
    }
    catch (error) {
        console.error('Error leaving queue:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to leave queue');
    }
});
// Scheduled function to process queue and update statuses
exports.processQueues = functions.pubsub
    .schedule('*/5 * * * *') // Run every 5 minutes
    .timeZone('UTC')
    .onRun(async (context) => {
    var _a, _b;
    try {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        // Get all active queues for today and future days
        const startOfToday = new Date();
        startOfToday.setHours(0, 0, 0, 0);
        const todayTimestamp = admin.firestore.Timestamp.fromDate(startOfToday);
        const activeQueuesQuery = await db.collection('queueSettings')
            .where('date', '>=', todayTimestamp)
            .where('isActive', '==', true)
            .get();
        if (activeQueuesQuery.empty) {
            console.log('No active queues found');
            return null;
        }
        console.log(`Processing ${activeQueuesQuery.size} active queues`);
        for (const queueDoc of activeQueuesQuery.docs) {
            const queueSettings = queueDoc.data();
            // Check if this queue should be active now
            const queueDate = queueSettings.date.toDate();
            const queueYear = queueDate.getFullYear();
            const queueMonth = queueDate.getMonth();
            const queueDay = queueDate.getDate();
            const queueStartTime = new Date(queueYear, queueMonth, queueDay, queueSettings.hour, 0, 0);
            const queueStartTimestamp = admin.firestore.Timestamp.fromDate(queueStartTime);
            // Skip processing queues that haven't started yet
            if (now.seconds < queueStartTimestamp.seconds) {
                console.log(`Queue ${queueDoc.id} hasn't started yet, skipping`);
                continue;
            }
            // Get all waiting entries in this queue, ordered by position
            const queueEntriesQuery = await db.collection('queueReservations')
                .where('providerId', '==', queueSettings.providerId)
                .where('governorateId', '==', queueSettings.governorateId)
                .where('preferredDate', '==', queueSettings.date)
                .where('preferredHour', '==', queueSettings.hour)
                .where('status', '==', 'waiting')
                .orderBy('queuePosition')
                .limit(10) // Process in batches for efficiency
                .get();
            if (queueEntriesQuery.empty) {
                console.log(`No waiting entries in queue ${queueDoc.id}`);
                continue;
            }
            console.log(`Processing ${queueEntriesQuery.size} entries in queue ${queueDoc.id}`);
            for (const entryDoc of queueEntriesQuery.docs) {
                const queueReservation = entryDoc.data();
                // Check if it's this person's turn based on estimated entry time
                if (queueReservation.estimatedEntryTime &&
                    now.seconds >= queueReservation.estimatedEntryTime.seconds) {
                    // Update status to 'processing'
                    await db.collection('queueReservations').doc(entryDoc.id).update({
                        status: 'processing',
                        updatedAt: now
                    });
                    // Get user's OneSignal player ID
                    const userDoc = await db.collection('users').doc(queueReservation.userId).get();
                    const playerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
                    // Send notification that it's their turn
                    if (playerId) {
                        await (0, push_utilities_1.sendNotification)({
                            playerIds: [playerId],
                            title: 'It\'s Your Turn!',
                            message: `Your turn has arrived for ${queueReservation.serviceName || 'your reservation'}`,
                            data: {
                                type: 'queue',
                                id: queueReservation.id,
                                status: 'processing'
                            }
                        });
                        // Also send using userId for external notification targeting
                        await (0, push_utilities_1.sendNotificationToUser)({
                            userId: queueReservation.userId,
                            title: 'It\'s Your Turn!',
                            message: `Your turn has arrived for ${queueReservation.serviceName || 'your reservation'}`,
                            data: {
                                type: 'queue',
                                id: queueReservation.id,
                                status: 'processing'
                            }
                        });
                    }
                    console.log(`Notified user ${queueReservation.userId} that it's their turn`);
                }
                else if (queueReservation.estimatedEntryTime &&
                    !queueReservation.reminderSent &&
                    (queueReservation.estimatedEntryTime.seconds - now.seconds) <= 10 * 60) {
                    // Send 10-minute reminder notification
                    const userDoc = await db.collection('users').doc(queueReservation.userId).get();
                    const playerId = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.oneSignalPlayerId;
                    if (playerId) {
                        await (0, push_utilities_1.sendNotification)({
                            playerIds: [playerId],
                            title: 'Almost Your Turn',
                            message: `You'll be up in about 10 minutes for ${queueReservation.serviceName || 'your reservation'}`,
                            data: {
                                type: 'queue',
                                id: queueReservation.id,
                                status: 'waiting'
                            }
                        });
                        // Also send using userId for external notification targeting
                        await (0, push_utilities_1.sendNotificationToUser)({
                            userId: queueReservation.userId,
                            title: 'Almost Your Turn',
                            message: `You'll be up in about 10 minutes for ${queueReservation.serviceName || 'your reservation'}`,
                            data: {
                                type: 'queue',
                                id: queueReservation.id,
                                status: 'waiting'
                            }
                        });
                        // Mark reminder as sent
                        await db.collection('queueReservations').doc(entryDoc.id).update({
                            reminderSent: true,
                            updatedAt: now
                        });
                        console.log(`Sent 10-minute reminder to user ${queueReservation.userId}`);
                    }
                }
            }
        }
        return null;
    }
    catch (error) {
        console.error('Error processing queues:', error);
        return null;
    }
});
// Function to complete a queue entry (called by service provider)
exports.completeQueueEntry = functions.https.onCall(async (data, context) => {
    var _a;
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to complete a queue entry');
    }
    const userId = context.auth.uid;
    const { queueReservationId } = data;
    // Input validation
    if (!queueReservationId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing queue reservation ID');
    }
    try {
        const db = admin.firestore();
        // Get queue reservation
        const queueReservationDoc = await db.collection('queueReservations').doc(queueReservationId).get();
        if (!queueReservationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Queue reservation not found');
        }
        const queueReservation = queueReservationDoc.data();
        // Check if the user is the service provider or an admin
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.data();
        const isAdmin = (userData === null || userData === void 0 ? void 0 : userData.role) === 'admin';
        const isProvider = (userData === null || userData === void 0 ? void 0 : userData.providerId) === queueReservation.providerId;
        if (!isAdmin && !isProvider) {
            throw new functions.https.HttpsError('permission-denied', 'You do not have permission to complete this queue entry');
        }
        // Update status to completed
        const now = admin.firestore.Timestamp.now();
        await db.collection('queueReservations').doc(queueReservationId).update({
            status: 'completed',
            updatedAt: now
        });
        // Notify the user
        const customerDoc = await db.collection('users').doc(queueReservation.userId).get();
        const playerId = (_a = customerDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
        if (playerId) {
            await (0, push_utilities_1.sendNotification)({
                playerIds: [playerId],
                title: 'Reservation Completed',
                message: `Your reservation for ${queueReservation.serviceName || 'the service'} has been completed`,
                data: {
                    type: 'queue',
                    id: queueReservationId,
                    status: 'completed'
                }
            });
            // Also send using userId for external notification targeting
            await (0, push_utilities_1.sendNotificationToUser)({
                userId: queueReservation.userId,
                title: 'Reservation Completed',
                message: `Your reservation for ${queueReservation.serviceName || 'the service'} has been completed`,
                data: {
                    type: 'queue',
                    id: queueReservationId,
                    status: 'completed'
                }
            });
        }
        return { success: true, message: 'Queue entry completed successfully' };
    }
    catch (error) {
        console.error('Error completing queue entry:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to complete queue entry');
    }
});
// Function to mark no-show (called by service provider)
exports.markNoShow = functions.https.onCall(async (data, context) => {
    var _a;
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to mark a no-show');
    }
    const userId = context.auth.uid;
    const { queueReservationId } = data;
    // Input validation
    if (!queueReservationId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing queue reservation ID');
    }
    try {
        const db = admin.firestore();
        // Get queue reservation
        const queueReservationDoc = await db.collection('queueReservations').doc(queueReservationId).get();
        if (!queueReservationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Queue reservation not found');
        }
        const queueReservation = queueReservationDoc.data();
        // Check if the user is the service provider or an admin
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.data();
        const isAdmin = (userData === null || userData === void 0 ? void 0 : userData.role) === 'admin';
        const isProvider = (userData === null || userData === void 0 ? void 0 : userData.providerId) === queueReservation.providerId;
        if (!isAdmin && !isProvider) {
            throw new functions.https.HttpsError('permission-denied', 'You do not have permission to mark this as no-show');
        }
        // Update status to no_show
        const now = admin.firestore.Timestamp.now();
        await db.collection('queueReservations').doc(queueReservationId).update({
            status: 'no_show',
            updatedAt: now
        });
        // Notify the user
        const customerDoc = await db.collection('users').doc(queueReservation.userId).get();
        const playerId = (_a = customerDoc.data()) === null || _a === void 0 ? void 0 : _a.oneSignalPlayerId;
        if (playerId) {
            await (0, push_utilities_1.sendNotification)({
                playerIds: [playerId],
                title: 'Missed Reservation',
                message: `You missed your turn for ${queueReservation.serviceName || 'the service'}`,
                data: {
                    type: 'queue',
                    id: queueReservationId,
                    status: 'no_show'
                }
            });
            // Also send using userId for external notification targeting
            await (0, push_utilities_1.sendNotificationToUser)({
                userId: queueReservation.userId,
                title: 'Missed Reservation',
                message: `You missed your turn for ${queueReservation.serviceName || 'the service'}`,
                data: {
                    type: 'queue',
                    id: queueReservationId,
                    status: 'no_show'
                }
            });
        }
        return { success: true, message: 'Queue entry marked as no-show' };
    }
    catch (error) {
        console.error('Error marking no-show:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to mark as no-show');
    }
});
// Scheduled function to auto-enroll users from reservations to queue
exports.autoEnrollReservationsToQueue = functions.pubsub
    .schedule('*/10 * * * *') // Run every 10 minutes
    .timeZone('UTC')
    .onRun(async (context) => {
    try {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        // Calculate time window for upcoming reservations (within the next 30 minutes)
        const thirtyMinutesFromNow = new admin.firestore.Timestamp(now.seconds + (30 * 60), now.nanoseconds);
        // Get confirmed queue-based reservations scheduled to start soon
        const upcomingReservationsQuery = await db.collection('reservations')
            .where('status', '==', 'confirmed')
            .where('queueBased', '==', true)
            .where('date', '<=', thirtyMinutesFromNow)
            .get();
        if (upcomingReservationsQuery.empty) {
            console.log('No upcoming queue-based reservations found');
            return null;
        }
        console.log(`Processing ${upcomingReservationsQuery.size} upcoming queue-based reservations`);
        const batch = db.batch();
        const promises = [];
        for (const reservationDoc of upcomingReservationsQuery.docs) {
            const reservation = reservationDoc.data();
            // Check if reservation date/time is within 30 mins from now
            const reservationTime = new Date(reservation.date.toDate().getFullYear(), reservation.date.toDate().getMonth(), reservation.date.toDate().getDate(), reservation.timeSlot, 0, 0);
            // Skip if the reservation time hasn't come yet or is more than 30 minutes away
            const reservationTimestamp = admin.firestore.Timestamp.fromDate(reservationTime);
            const timeDiffInMinutes = (reservationTimestamp.seconds - now.seconds) / 60;
            // Skip if already processed or too far in the future
            if (timeDiffInMinutes > 30)
                continue;
            // Check if already in queue
            const existingQueueQuery = await db.collection('queueReservations')
                .where('userId', '==', reservation.userId)
                .where('providerId', '==', reservation.providerId)
                .where('preferredDate', '==', reservation.date)
                .where('preferredHour', '==', reservation.timeSlot)
                .where('status', 'in', ['waiting', 'processing'])
                .get();
            if (!existingQueueQuery.empty) {
                console.log(`User ${reservation.userId} already in queue for reservation ${reservation.id}`);
                continue;
            }
            // Get or create queue settings for this time slot
            const queueSettingsId = `${reservation.providerId}_${reservation.governorateId}_${reservation.serviceId || 'general'}_${reservation.date.toDate().toISOString().slice(0, 10)}_${reservation.timeSlot}`;
            const queueSettingsRef = db.collection('queueSettings').doc(queueSettingsId);
            const queueSettingsDoc = await queueSettingsRef.get();
            let queueSettings;
            if (!queueSettingsDoc.exists) {
                // Create new queue settings if it doesn't exist
                const defaultProcessingRate = 10; // 10 minutes per person by default
                queueSettings = {
                    id: queueSettingsId,
                    providerId: reservation.providerId,
                    governorateId: reservation.governorateId,
                    serviceId: reservation.serviceId,
                    date: reservation.date,
                    hour: reservation.timeSlot,
                    maxCapacity: 50, // Default max capacity
                    currentPosition: 0,
                    processingRate: defaultProcessingRate,
                    isActive: true,
                    lastUpdated: now
                };
                await queueSettingsRef.set(queueSettings);
            }
            else {
                queueSettings = queueSettingsDoc.data();
            }
            // Calculate queue position and estimated entry time
            const nextPosition = queueSettings.currentPosition + 1;
            // Calculate estimated entry time: current time + (position * processing rate in minutes)
            const estimatedWaitMinutes = nextPosition * queueSettings.processingRate;
            const estimatedEntryTime = new admin.firestore.Timestamp(now.seconds + (estimatedWaitMinutes * 60), now.nanoseconds);
            // Get user information
            const userDoc = await db.collection('users').doc(reservation.userId).get();
            if (!userDoc.exists) {
                console.error(`User ${reservation.userId} not found for reservation ${reservation.id}`);
                continue;
            }
            const userData = userDoc.data();
            // Create queue reservation
            const queueReservationRef = db.collection('queueReservations').doc();
            const queueReservation = {
                id: queueReservationRef.id,
                userId: reservation.userId,
                userName: (userData === null || userData === void 0 ? void 0 : userData.name) || 'Unknown User',
                providerId: reservation.providerId,
                governorateId: reservation.governorateId,
                serviceId: reservation.serviceId,
                serviceName: reservation.serviceName,
                preferredDate: reservation.date,
                preferredHour: reservation.timeSlot,
                attendees: reservation.attendees || [{
                        userId: reservation.userId,
                        name: (userData === null || userData === void 0 ? void 0 : userData.name) || 'Unknown User',
                        type: 'primary',
                        status: 'confirmed',
                        paymentStatus: 'pending',
                        isHost: true
                    }],
                queuePosition: nextPosition,
                estimatedEntryTime,
                status: 'waiting',
                createdAt: now,
                notes: reservation.notes,
                reminderSent: false
            };
            // Update batch operations
            batch.set(queueReservationRef, queueReservation);
            batch.update(queueSettingsRef, {
                currentPosition: nextPosition,
                lastUpdated: now
            });
            // Send notification about auto enrollment
            const playerId = userData === null || userData === void 0 ? void 0 : userData.oneSignalPlayerId;
            if (playerId) {
                // Format estimated entry time
                const entryTime = estimatedEntryTime.toDate();
                const formattedTime = entryTime.toLocaleTimeString('en-US', {
                    hour: 'numeric',
                    minute: 'numeric',
                    hour12: true
                });
                promises.push((0, push_utilities_1.sendNotification)({
                    playerIds: [playerId],
                    title: 'Queue Ready',
                    message: `You've been automatically added to the queue for ${reservation.serviceName || 'your reservation'}. You are #${nextPosition} in line. Estimated entry time: ${formattedTime}`,
                    data: {
                        type: 'queue',
                        id: queueReservationRef.id,
                        queuePosition: nextPosition
                    }
                }));
                promises.push((0, push_utilities_1.sendNotificationToUser)({
                    userId: reservation.userId,
                    title: 'Queue Ready',
                    message: `You've been automatically added to the queue for ${reservation.serviceName || 'your reservation'}. You are #${nextPosition} in line. Estimated entry time: ${formattedTime}`,
                    data: {
                        type: 'queue',
                        id: queueReservationRef.id,
                        queuePosition: nextPosition
                    }
                }));
            }
            console.log(`Auto-enrolled user ${reservation.userId} into queue for reservation ${reservation.id}`);
        }
        // Commit batch operations
        await batch.commit();
        // Wait for all notification promises to resolve
        if (promises.length > 0) {
            await Promise.all(promises);
        }
        return null;
    }
    catch (error) {
        console.error('Error auto-enrolling reservations to queue:', error);
        return null;
    }
});
// Cloud function to get queue status and history for a user
exports.getUserQueueHistory = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to view queue history');
    }
    const userId = context.auth.uid;
    const { limit = 10 } = data;
    try {
        const db = admin.firestore();
        // Get active queues for this user
        const activeQueuesQuery = await db.collection('queueReservations')
            .where('userId', '==', userId)
            .where('status', 'in', ['waiting', 'processing'])
            .orderBy('preferredDate', 'asc')
            .orderBy('preferredHour', 'asc')
            .get();
        // Get past queues for this user
        const pastQueuesQuery = await db.collection('queueReservations')
            .where('userId', '==', userId)
            .where('status', 'in', ['completed', 'cancelled', 'no_show'])
            .orderBy('preferredDate', 'desc')
            .limit(limit)
            .get();
        const activeQueues = [];
        for (const doc of activeQueuesQuery.docs) {
            const queueData = doc.data();
            // Get people ahead in queue
            const peopleAheadQuery = await db.collection('queueReservations')
                .where('providerId', '==', queueData.providerId)
                .where('governorateId', '==', queueData.governorateId)
                .where('preferredDate', '==', queueData.preferredDate)
                .where('preferredHour', '==', queueData.preferredHour)
                .where('queuePosition', '<', queueData.queuePosition)
                .where('status', 'in', ['waiting', 'processing'])
                .get();
            const peopleAhead = peopleAheadQuery.size;
            activeQueues.push({
                ...queueData,
                peopleAhead
            });
        }
        const pastQueues = pastQueuesQuery.docs.map(doc => doc.data());
        return {
            success: true,
            activeQueues,
            pastQueues
        };
    }
    catch (error) {
        console.error('Error getting user queue history:', error);
        throw new functions.https.HttpsError('internal', error instanceof Error ? error.message : 'Failed to get queue history');
    }
});
//# sourceMappingURL=queue_management.js.map