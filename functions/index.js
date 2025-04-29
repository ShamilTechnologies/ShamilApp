const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK (ensure this is done only once)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Creates reservation documents in Firestore after checking for availability.
 * Expects data payload defined in ReservationBloc.
 *
 * @param {object} data - The data payload from the client.
 * @param {string} data.userId - ID of the user booking.
 * @param {string} data.providerId - ID of the service provider.
 * @param {string} data.serviceId - ID of the specific service.
 * @param {string} data.serviceName - Name of the service.
 * @param {number} data.serviceDurationMinutes - Duration in minutes.
 * @param {number} data.servicePrice - Price of the service.
 * @param {number} data.reservationDateMillis - Start of the reservation day (UTC milliseconds).
 * @param {Array<{startTimeMillis: number, endTimeMillis: number}>} data.requestedSlots - List of requested slots.
 * @param {functions.https.CallableContext} context - Function context (includes auth).
 * @returns {Promise<{success: boolean, message?: string, error?: string}>} - Result object.
 */
exports.createReservation = functions.https.onCall(async (data, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }
  const callingUserId = context.auth.uid;

  // 2. Input Validation (Basic)
  if (
    !data ||
    !data.userId ||
    !data.providerId ||
    !data.serviceId ||
    !data.serviceName ||
    !data.serviceDurationMinutes ||
    data.servicePrice == null || // Check for null price explicitly
    !data.reservationDateMillis ||
    !data.requestedSlots ||
    !Array.isArray(data.requestedSlots) ||
    data.requestedSlots.length === 0
  ) {
    functions.logger.error("Validation Error: Missing or invalid data.", data);
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing or invalid data provided for reservation."
    );
  }

  // Ensure the calling user matches the userId in the data (security check)
   if (callingUserId !== data.userId) {
     functions.logger.error(`Permission Denied: User ${callingUserId} attempting to book for ${data.userId}`);
      throw new functions.https.HttpsError(
        "permission-denied",
        "User ID mismatch. Cannot book for another user."
      );
   }


  const providerId = data.providerId;
  const requestedSlots = data.requestedSlots;

   functions.logger.info(`Reservation request received for user ${callingUserId}, provider ${providerId}`, { structuredData: true, payload: data });


  try {
    // 3. Check for Conflicts within a Firestore Transaction
    const conflictFound = await db.runTransaction(async (transaction) => {
      // Construct query range for the entire day based on reservationDateMillis
      const startOfDay = admin.firestore.Timestamp.fromMillis(data.reservationDateMillis);
      const endOfDay = admin.firestore.Timestamp.fromMillis(data.reservationDateMillis + (24 * 60 * 60 * 1000) - 1);

      functions.logger.debug(`Checking conflicts for provider ${providerId} between ${startOfDay.toDate()} and ${endOfDay.toDate()}`);

      // Query for existing confirmed reservations for this provider on the given day
      const reservationsRef = db.collection("reservations"); // Ensure collection name is correct
      const query = reservationsRef
        .where("providerId", "==", providerId)
        .where("status", "==", "confirmed") // Only check against confirmed bookings
        .where("reservationStartTime", ">=", startOfDay)
        .where("reservationStartTime", "<=", endOfDay); // Check within the day

      // Get existing reservations within the transaction
      const existingReservationsSnapshot = await transaction.get(query);
      functions.logger.debug(`Found ${existingReservationsSnapshot.docs.length} existing confirmed reservations for the day.`);

      // Check each requested slot for overlap with existing confirmed reservations
      for (const requestedSlot of requestedSlots) {
        // Validate slot data structure
        if (requestedSlot.startTimeMillis == null || requestedSlot.endTimeMillis == null) {
            functions.logger.error("Invalid slot data received in requestedSlots array", requestedSlot);
            throw new functions.https.HttpsError("invalid-argument", "Invalid slot data format received.");
        }

        const reqStart = admin.firestore.Timestamp.fromMillis(requestedSlot.startTimeMillis);
        const reqEnd = admin.firestore.Timestamp.fromMillis(requestedSlot.endTimeMillis);

        for (const doc of existingReservationsSnapshot.docs) {
          const existingData = doc.data();
          // Add checks for potentially missing timestamp fields in existing data
          if (!existingData.reservationStartTime || !existingData.reservationEndTime) {
              functions.logger.warn(`Skipping conflict check for existing reservation ${doc.id} due to missing timestamps.`);
              continue;
          }
          const existingStart = existingData.reservationStartTime; // Already a Timestamp
          const existingEnd = existingData.reservationEndTime;     // Already a Timestamp

          // Check for overlap: (ReqStart < ExistingEnd) AND (ReqEnd > ExistingStart)
          if (reqStart < existingEnd && reqEnd > existingStart) {
            functions.logger.warn(`Conflict detected: Requested slot ${reqStart.toDate()}-${reqEnd.toDate()} overlaps with existing ${existingStart.toDate()}-${existingEnd.toDate()}`);
            return true; // Conflict found, exit transaction returning true
          }
        }
      }

      // If loop completes without finding conflicts, proceed to create reservations
      functions.logger.info(`No conflicts found for ${requestedSlots.length} requested slots. Proceeding to create.`);

      // 4. Create New Reservation Documents (within the transaction)
      const now = admin.firestore.FieldValue.serverTimestamp();
      for (const requestedSlot of requestedSlots) {
        const newReservationRef = reservationsRef.doc(); // Auto-generate document ID

        // Define the structure explicitly for clarity, matching ReservationDocument idea
        const reservationDocData = {
          userId: data.userId,
          providerId: data.providerId,
          serviceId: data.serviceId,
          serviceName: data.serviceName,
          serviceDurationMinutes: data.serviceDurationMinutes,
          servicePrice: data.servicePrice,
          reservationStartTime: admin.firestore.Timestamp.fromMillis(requestedSlot.startTimeMillis),
          reservationEndTime: admin.firestore.Timestamp.fromMillis(requestedSlot.endTimeMillis),
          status: "confirmed", // Set status directly to confirmed
          createdAt: now,
          lastUpdatedAt: now,
        };
        transaction.set(newReservationRef, reservationDocData);
         functions.logger.debug(`Added reservation document ${newReservationRef.id} to transaction.`);
      }

      return false; // No conflict found, transaction will commit writes
    }); // End of Firestore Transaction

    // 5. Return Result based on Transaction Outcome
    if (conflictFound) {
      functions.logger.warn("Transaction failed due to slot conflict.");
      return { success: false, error: "One or more selected time slots are no longer available. Please select again." };
    } else {
      functions.logger.info(`Successfully created ${requestedSlots.length} reservation(s) for user ${callingUserId}.`);
      // TODO: Optionally trigger a notification to the user/provider here
      return { success: true, message: `${requestedSlots.length} reservation(s) confirmed!` };
    }

  } catch (error) {
    functions.logger.error("Error creating reservation:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error; // Re-throw HttpsError
    }
    // Log generic errors
    throw new functions.https.HttpsError(
      "internal",
      "An unexpected error occurred while creating the reservation.",
      // Avoid sending raw error details to client unless necessary and safe
      // error
    );
  }
});

