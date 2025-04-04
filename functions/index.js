/**
 * Cloud Functions for Firebase v2 SDK Example
 * Handles social interactions (Friends & Family) and sends notifications.
 */

// v2 Imports: Import specific trigger functions
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions"); // Use logger for logging
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
try {
  admin.initializeApp();
} catch (e) {
  logger.error("Admin Init Error:", e);
}

const db = admin.firestore();
const messaging = admin.messaging();

// --- Friend Request Functions (v2 Syntax) ---

/**
 * Triggered when a 'pending_sent' friend request is created by the sender.
 * Creates the corresponding 'pending_received' request for the target user
 * and sends a notification.
 */
exports.onFriendRequestSent = onDocumentCreated("endUsers/{senderId}/friends/{targetUserId}", async (event) => {
  const snap = event.data; // DocumentSnapshot
  if (!snap) {
    logger.warn("No data associated with the event");
    return null;
  }
  const requestData = snap.data();
  const { senderId, targetUserId } = event.params;

  if (requestData.status !== "pending_sent") {
    logger.info(
      `Friend doc created for ${senderId}->${targetUserId} but status ` +
      `is not 'pending_sent' (${requestData.status}). No action.`,
    );
    return null;
  }

  logger.info(
    `Friend request sent from ${senderId} to ${targetUserId}. ` +
    `Creating reciprocal doc and sending notification.`,
  );

  const senderName = requestData.senderName || requestData.displayName || "Someone";
  const senderProfilePicUrl = requestData.senderProfilePicUrl ||
                              requestData.profilePicUrl || null;

  // Create the 'pending_received' document for the target user
  const targetFriendRef = db
    .collection("endUsers")
    .doc(targetUserId)
    .collection("friends")
    .doc(senderId);

  try {
    await targetFriendRef.set(
      {
        status: "pending_received",
        userId: senderId,
        displayName: senderName,
        profilePicUrl: senderProfilePicUrl,
        requestReceivedAt: requestData.requestSentAt ||
                           admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    logger.info(
      `Created 'pending_received' doc for ${targetUserId} from ${senderId}.`,
    );

    // --- Send Notification ---
    return sendFcmNotification(
      targetUserId,
      "New Friend Request!",
      `${senderName} wants to be your friend.`,
      { type: "friend_request", senderId: senderId },
    );
  } catch (error) {
    logger.error(
      `Error handling friend request sent from ${senderId} to ` +
      `${targetUserId}:`,
      error,
    );
    return null;
  }
});

/**
 * Triggered when a friend request status is updated to 'accepted'.
 * Updates the corresponding document for the other user.
 * Sends a notification to the original requester.
 */
exports.onFriendRequestAccepted = onDocumentUpdated("endUsers/{accepterId}/friends/{requesterId}", async (event) => {
  const beforeSnap = event.data?.before; // DocumentSnapshot before
  const afterSnap = event.data?.after; // DocumentSnapshot after
  if (!beforeSnap || !afterSnap) {
    logger.warn("No before or after data associated with the update event");
    return null;
  }
  const beforeData = beforeSnap.data();
  const afterData = afterSnap.data();
  const { accepterId, requesterId } = event.params;

  if (
    !(beforeData.status === "pending_received" &&
      afterData.status === "accepted")
  ) {
    logger.info(
      `Friend doc update for ${accepterId}<-${requesterId}, but not an ` +
      `acceptance. Status: ${beforeData.status} -> ${afterData.status}.`,
    );
    return null;
  }

  logger.info(
    `Friend request accepted by ${accepterId} from ${requesterId}. ` +
    `Updating reciprocal doc and sending notification.`,
  );

  const accepterName = afterData.displayName || "Someone";
  const accepterProfilePicUrl = afterData.profilePicUrl || null;

  // Update the requester's document status to 'accepted'
  const requesterFriendRef = db
    .collection("endUsers")
    .doc(requesterId)
    .collection("friends")
    .doc(accepterId);

  try {
    await requesterFriendRef.update({
      status: "accepted",
      friendedAt: afterData.friendedAt ||
                  admin.firestore.FieldValue.serverTimestamp(),
      displayName: accepterName,
      profilePicUrl: accepterProfilePicUrl,
    });
    logger.info(
      `Updated requester's (${requesterId}) friend doc for ${accepterId} ` +
      `to 'accepted'.`,
    );

    // --- Send Acceptance Notification ---
    return sendFcmNotification(
      requesterId,
      "Friend Request Accepted!",
      `${accepterName} accepted your friend request.`,
      { type: "friend_accepted", accepterId: accepterId },
    );
  } catch (error) {
    logger.error(
      `Error handling friend request acceptance by ${accepterId} from ` +
      `${requesterId}:`,
      error,
    );
    return null;
  }
});


/**
 * Triggered when a friend/request document is deleted.
 * Deletes the corresponding document in the other user's subcollection.
 */
exports.onFriendRelationshipDeleted = onDocumentDeleted("endUsers/{userId1}/friends/{userId2}", async (event) => {
  const snap = event.data; // DocumentSnapshot before deletion
  if (!snap) {
    logger.warn("No data associated with the delete event");
    return null;
  }
  const deletedData = snap.data();
  const { userId1, userId2 } = event.params;

  logger.info(
    `Friendship/Request doc deleted for ${userId1} -> ${userId2}. ` +
    `Status was: ${deletedData.status}. Deleting reciprocal doc.`,
  );

  const reciprocalRef = db
    .collection("endUsers")
    .doc(userId2)
    .collection("friends")
    .doc(userId1);

  try {
    const reciprocalDoc = await reciprocalRef.get();
    if (reciprocalDoc.exists) {
      await reciprocalRef.delete();
      logger.info(
        `Successfully deleted reciprocal friend/request doc for ` +
        `${userId2} -> ${userId1}.`,
      );
    } else {
      logger.info(
        `Reciprocal friend/request doc for ${userId2} -> ${userId1} ` +
        `not found.`,
      );
    }
    return null;
  } catch (error) {
    logger.error(
      `Error deleting reciprocal friend/request doc for ${userId2} -> ` +
      `${userId1}:`,
      error,
    );
    return null;
  }
});


// --- Family Request Functions (v2 Syntax) ---

/**
 * Triggered when a 'pending_sent' family request is created by the sender.
 * Creates the corresponding 'pending_received' request for the target user
 * and sends a notification.
 */
exports.onFamilyRequestSent = onDocumentCreated("endUsers/{senderId}/familyMembers/{targetUserId}", async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const requestData = snap.data();
  const { senderId, targetUserId } = event.params;

  if (requestData.status !== "pending_sent") {
    logger.info(
      `Family doc created for ${senderId}->${targetUserId} but status ` +
      `is not 'pending_sent' (${requestData.status}).`,
    );
    return null;
  }
  logger.info(
    `Family request sent from ${senderId} to ${targetUserId}. ` +
    `Creating reciprocal doc and sending notification.`,
  );

  const senderName = requestData.senderName || "Someone";
  const senderProfilePicUrl = requestData.senderProfilePicUrl || null;
  const relationship = requestData.relationship || "Family";

  // Create 'pending_received' doc for the target user
  const targetFamilyRef = db
    .collection("endUsers")
    .doc(targetUserId)
    .collection("familyMembers")
    .doc(senderId);

  try {
    await targetFamilyRef.set(
      {
        status: "pending_received",
        userId: senderId,
        name: senderName,
        profilePicUrl: senderProfilePicUrl,
        relationship: relationship,
        addedAt: requestData.addedAt ||
                 admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    logger.info(
      `Created 'pending_received' family doc for ${targetUserId} ` +
      `from ${senderId}.`,
    );

    // --- Send Notification ---
    return sendFcmNotification(
      targetUserId,
      "New Family Request!",
      `${senderName} added you as ${relationship}.`,
      { type: "family_request", senderId: senderId },
    );
  } catch (error) {
    logger.error(
      `Error handling family request sent from ${senderId} to ` +
      `${targetUserId}:`,
      error,
    );
    return null;
  }
});

/**
 * Triggered when a family request status is updated to 'accepted'.
 * Updates the corresponding document for the original requester.
 * Sends a notification to the original requester.
 */
exports.onFamilyRequestAccepted = onDocumentUpdated("endUsers/{accepterId}/familyMembers/{requesterId}", async (event) => {
  const beforeSnap = event.data?.before;
  const afterSnap = event.data?.after;
  if (!beforeSnap || !afterSnap) return null;
  const beforeData = beforeSnap.data();
  const afterData = afterSnap.data();
  const { accepterId, requesterId } = event.params;

  if (
    !(beforeData.status === "pending_received" &&
      afterData.status === "accepted")
  ) {
    logger.info(
      `Family doc update for ${accepterId}<-${requesterId}, but not an ` +
      `acceptance.`,
    );
    return null;
  }
  logger.info(
    `Family request accepted by ${accepterId} from ${requesterId}. ` +
    `Updating reciprocal doc and sending notification.`,
  );

  const accepterName = afterData.name || "Someone";
  const accepterProfilePicUrl = afterData.profilePicUrl || null;

  // Update the requester's document status to 'accepted'
  const requesterFamilyRef = db
    .collection("endUsers")
    .doc(requesterId)
    .collection("familyMembers")
    .doc(accepterId);

  try {
    await requesterFamilyRef.update({
      status: "accepted",
      addedAt: afterData.addedAt ||
               admin.firestore.FieldValue.serverTimestamp(),
      name: accepterName,
      profilePicUrl: accepterProfilePicUrl,
    });
    logger.info(
      `Updated requester's (${requesterId}) family doc for ${accepterId} ` +
      `to 'accepted'.`,
    );

    // --- Send Acceptance Notification ---
    return sendFcmNotification(
      requesterId,
      "Family Request Accepted!",
      `${accepterName} accepted your family request.`,
      { type: "family_accepted", accepterId: accepterId },
    );
  } catch (error) {
    logger.error(
      `Error handling family request acceptance by ${accepterId} from ` +
      `${requesterId}:`,
      error,
    );
    return null;
  }
});


/**
 * Triggered when a family/request document is deleted.
 * Deletes the corresponding document in the other user's subcollection.
 */
exports.onFamilyRelationshipDeleted = onDocumentDeleted("endUsers/{userId1}/familyMembers/{userId2}", async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const deletedData = snap.data();
  const { userId1, userId2 } = event.params;

  if (
    deletedData.status === "pending_sent" ||
    deletedData.status === "pending_received" ||
    deletedData.status === "accepted"
  ) {
    logger.info(
      `Family relationship doc deleted for ${userId1} -> ${userId2}. ` +
      `Status was: ${deletedData.status}. Deleting reciprocal doc.`,
    );
    const reciprocalRef = db
      .collection("endUsers")
      .doc(userId2)
      .collection("familyMembers")
      .doc(userId1);
    try {
      const reciprocalDoc = await reciprocalRef.get();
      if (reciprocalDoc.exists) {
        await reciprocalRef.delete();
        logger.info(
          `Successfully deleted reciprocal family doc for ` +
          `${userId2} -> ${userId1}.`,
        );
      } else {
        logger.info(
          `Reciprocal family doc for ${userId2} -> ${userId1} not found.`,
        );
      }
      return null;
    } catch (error) {
      logger.error(
        `Error deleting reciprocal family doc for ${userId2} -> ${userId1}:`,
        error,
      );
      return null;
    }
  } else {
    logger.info(
      `External family member doc deleted for ${userId1}. No reciprocal ` +
      `action needed.`,
    );
    return null;
  }
});


// --- Helper Functions ---

/**
 * Sends an FCM notification to a specific user.
 * @param {string} userId The UID of the user to notify.
 * @param {string} title Notification title.
 * @param {string} body Notification body.
 * @param {object} [dataPayload={}] Optional data payload.
 * @return {Promise<admin.messaging.MessagingDevicesResponse|null>} FCM response.
 */
async function sendFcmNotification(userId, title, body, dataPayload = {}) {
  logger.info(`Preparing notification for user ${userId}: Title='${title}'`);
  const userRef = db.collection("endUsers").doc(userId);
  let userData;
  try {
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      logger.error(`User ${userId} not found for notification.`);
      return null;
    }
    userData = userDoc.data();
  } catch (error) {
    logger.error(`Error fetching user document ${userId}:`, error);
    return null;
  }

  const tokens = userData.fcmTokens;
  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    logger.info(`No FCM tokens found for user ${userId}.`);
    return null;
  }

  const payload = {
    notification: { title: title, body: body },
    data: dataPayload,
  };

  logger.info(`Sending notification to ${tokens.length} tokens for user ${userId}`);
  try {
    const response = await messaging.sendToDevice(tokens, payload);
    logger.info("Successfully sent message:", JSON.stringify(response));
    await cleanupTokens(response, tokens, userRef); // Clean up invalid tokens
    return response;
  } catch (error) {
    logger.error("Error sending FCM message:", error);
    return null;
  }
}

/**
 * Cleans up invalid FCM tokens from Firestore based on the send response.
 * @param {admin.messaging.MessagingDevicesResponse} response FCM send response.
 * @param {string[]} tokens List of tokens notification was sent to.
 * @param {FirebaseFirestore.DocumentReference} userRef Firestore ref to user doc.
 * @return {Promise<void>}
 */
async function cleanupTokens(response, tokens, userRef) {
  const tokensToRemove = [];
  response.results.forEach((result, index) => {
    const error = result.error;
    if (error) {
      logger.error("Failure sending notification to", tokens[index], error);
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        tokensToRemove.push(tokens[index]);
      }
    }
  });

  if (tokensToRemove.length > 0) {
    logger.info(`Removing ${tokensToRemove.length} invalid tokens.`);
    try {
       await userRef.update({
         fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
       });
       logger.info("Invalid tokens removed from Firestore.");
    } catch (e) {
       logger.error("Error removing invalid tokens from Firestore:", e);
    }
  }
}
