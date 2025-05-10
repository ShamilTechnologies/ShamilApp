/// Utility class to standardize Firestore collection and document paths
class FirestorePaths {
  // Root collections
  static String endUsers() => 'endUsers';
  static String serviceProviders() => 'serviceProviders';

  // User subcollections
  static String userReservations(String userId) =>
      '${endUsers()}/$userId/reservations';
  static String userSubscriptions(String userId) =>
      '${endUsers()}/$userId/subscriptions';
  static String userFavorites(String userId) =>
      '${endUsers()}/$userId/favorites';
  static String userNotifications(String userId) =>
      '${endUsers()}/$userId/notifications';

  // Service provider subcollections
  static String providerServices(String providerId) =>
      '${serviceProviders()}/$providerId/services';
  static String providerPlans(String providerId) =>
      '${serviceProviders()}/$providerId/plans';
  static String providerPendingReservations(String providerId) =>
      '${serviceProviders()}/$providerId/pendingReservations';
  static String providerConfirmedReservations(String providerId) =>
      '${serviceProviders()}/$providerId/confirmedReservations';
  static String providerActiveSubscriptions(String providerId) =>
      '${serviceProviders()}/$providerId/activeSubscriptions';

  // Document paths - User
  static String userDocument(String userId) => '${endUsers()}/$userId';
  static String userReservationDocument(String userId, String reservationId) =>
      '${userReservations(userId)}/$reservationId';
  static String userSubscriptionDocument(
          String userId, String subscriptionId) =>
      '${userSubscriptions(userId)}/$subscriptionId';

  // Document paths - Provider
  static String providerDocument(String providerId) =>
      '${serviceProviders()}/$providerId';
  static String providerServiceDocument(String providerId, String serviceId) =>
      '${providerServices(providerId)}/$serviceId';
  static String providerPlanDocument(String providerId, String planId) =>
      '${providerPlans(providerId)}/$planId';
}
