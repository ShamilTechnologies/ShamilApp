// Use v2 SDK import style for https and logger
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger"); // Use v2 logger
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK (ensure this is done only once)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Creates reservation documents in Firestore after checking for availability.
 * Expects data payload defined in ReservationBloc.
 * Uses v2 SDK syntax. App Check enforcement is DISABLED for debugging.
 *
 * @param {onCall.Request} request - The request object containing data, auth, and app check context.
 * @param {object} request.data - The data payload from the client.
 * @param {string} request.data.userId - ID of the user booking.
 * @param {string} request.data.providerId - ID of the service provider.
 * @param {string} request.data.serviceId - ID of the specific service.
 * @param {string} request.data.serviceName - Name of the service.
 * @param {number} request.data.serviceDurationMinutes - Duration in minutes.
 * @param {number} request.data.servicePrice - Price of the service.
 * @param {number} data.reservationDateMillis - Start of the reservation day (UTC milliseconds).
 * @param {Array<{startTimeMillis: number, endTimeMillis: number}>} request.data.requestedSlots - List of requested slots.
 * @param {onCall.AuthData | undefined} request.auth - Authentication context.
 * @param {onCall.AppCheckData | undefined} request.app - App Check context (may be undefined or invalid if enforcement is off).
 * @returns {Promise<{success: boolean, message?: string, error?: string}>} - Result object.
 */
exports.createReservation = onCall(
  {
    // Runtime options for the function
    // *** App Check Enforcement DISABLED for debugging ***
    // enforceAppCheck: true, // Reject requests with missing or invalid App Check tokens.
    // consumeAppCheckToken: true,  // Consume the token after verification (recommended).
    // region: 'your-region' // Optional: specify region if not us-central1
  },
  async (request) => {
    // 1. Authentication Check (Still important!)
    // Access auth context from request.auth
    if (!request.auth) {
      logger.error("Function called without authentication context (auth check).");
      // Use HttpsError from v2 import
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    // User is authenticated via Firebase Auth, get their UID
    const callingUserId = request.auth.uid;
    logger.info(`Function called by authenticated user: ${callingUserId}`);

    // Access payload data from request.data
    const data = request.data;

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
      logger.error("Validation Error: Missing or invalid data.", data);
      throw new HttpsError(
        "invalid-argument",
        "Missing or invalid data provided for reservation."
      );
    }

    // Ensure the calling user matches the userId in the data (security check)
    if (callingUserId !== data.userId) {
      logger.error(`Permission Denied: User ${callingUserId} attempting to book for ${data.userId}`);
        throw new HttpsError(
          "permission-denied",
          "User ID mismatch. Cannot book for another user."
        );
    }


    const providerId = data.providerId;
    const requestedSlots = data.requestedSlots;

    logger.info(`Reservation request received for user ${callingUserId}, provider ${providerId}`, { structuredData: true, payload: data });


    try {
      // 3. Check for Conflicts within a Firestore Transaction
      const conflictFound = await db.runTransaction(async (transaction) => {
        // Construct query range for the entire day based on reservationDateMillis
        const startOfDay = admin.firestore.Timestamp.fromMillis(data.reservationDateMillis);
        // Calculate end of day (add 24 hours worth of milliseconds, subtract 1 ms)
        const endOfDay = admin.firestore.Timestamp.fromMillis(data.reservationDateMillis + (24 * 60 * 60 * 1000) - 1);

        logger.debug(`Checking conflicts for provider ${providerId} between ${startOfDay.toDate()} and ${endOfDay.toDate()}`);

        // Query for existing confirmed reservations for this provider on the given day
        const reservationsRef = db.collection("reservations"); // Ensure collection name is correct
        const query = reservationsRef
          .where("providerId", "==", providerId)
          .where("status", "==", "confirmed") // Only check against confirmed bookings
          .where("reservationStartTime", ">=", startOfDay)
          .where("reservationStartTime", "<=", endOfDay); // Check within the day

        // Get existing reservations within the transaction
        const existingReservationsSnapshot = await transaction.get(query);
        logger.debug(`Found ${existingReservationsSnapshot.docs.length} existing confirmed reservations for the day.`);

        // Check each requested slot for overlap with existing confirmed reservations
        for (const requestedSlot of requestedSlots) {
          // Validate slot data structure
          if (requestedSlot.startTimeMillis == null || requestedSlot.endTimeMillis == null) {
              logger.error("Invalid slot data received in requestedSlots array", requestedSlot);
              // Throwing inside transaction will cause it to fail
              throw new HttpsError("invalid-argument", "Invalid slot data format received.");
          }

          const reqStart = admin.firestore.Timestamp.fromMillis(requestedSlot.startTimeMillis);
          const reqEnd = admin.firestore.Timestamp.fromMillis(requestedSlot.endTimeMillis);

          for (const doc of existingReservationsSnapshot.docs) {
            const existingData = doc.data();
            // Add checks for potentially missing timestamp fields in existing data
            if (!existingData.reservationStartTime || !existingData.reservationEndTime) {
                logger.warn(`Skipping conflict check for existing reservation ${doc.id} due to missing timestamps.`);
                continue;
            }
            const existingStart = existingData.reservationStartTime; // Already a Timestamp
            const existingEnd = existingData.reservationEndTime;     // Already a Timestamp

            // Check for overlap: (ReqStart < ExistingEnd) AND (ReqEnd > ExistingStart)
            if (reqStart < existingEnd && reqEnd > existingStart) {
              logger.warn(`Conflict detected: Requested slot ${reqStart.toDate()}-${reqEnd.toDate()} overlaps with existing ${existingStart.toDate()}-${existingEnd.toDate()}`);
              return true; // Conflict found, exit transaction returning true
            }
          }
        }

        // If loop completes without finding conflicts, proceed to create reservations
        logger.info(`No conflicts found for ${requestedSlots.length} requested slots. Proceeding to create.`);

        // 4. Create New Reservation Documents (within the transaction)
        const now = admin.firestore.FieldValue.serverTimestamp();
        for (const requestedSlot of requestedSlots) {
          const newReservationRef = reservationsRef.doc(); // Auto-generate document ID

          // Define the structure explicitly for clarity
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
           logger.debug(`Added reservation document ${newReservationRef.id} to transaction.`);
        }

        return false; // No conflict found, transaction will commit writes
      }); // End of Firestore Transaction

      // 5. Return Result based on Transaction Outcome
      if (conflictFound) {
        logger.warn("Transaction failed due to slot conflict.");
        return { success: false, error: "One or more selected time slots are no longer available. Please select again." };
      } else {
        logger.info(`Successfully created ${requestedSlots.length} reservation(s) for user ${callingUserId}.`);
        // TODO: Optionally trigger a notification to the user/provider here
        return { success: true, message: `${requestedSlots.length} reservation(s) confirmed!` };
      }

    } catch (error) {
      logger.error("Error creating reservation:", error);
      // Check if it's an HttpsError we threw intentionally (like validation/conflict)
      if (error instanceof HttpsError) {
        throw error; // Re-throw HttpsError to be handled by the client correctly
      }
      // Log other types of errors (e.g., Firestore errors within transaction)
      throw new HttpsError(
        "internal",
        "An unexpected error occurred while creating the reservation.",
        // Avoid sending raw error details to client unless necessary and safe
        // error
      );
    }
});