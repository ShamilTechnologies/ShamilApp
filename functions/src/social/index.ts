import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Simple test function to debug authentication issues
export const testAuthentication = functions.https.onCall(
  async (data: any, context) => {
    console.log('🧪 Test function called');
    console.log('🔍 Context:', {
      auth: context.auth ? {
        uid: context.auth.uid,
        token: context.auth.token ? 'Present' : 'Missing'
      } : 'No auth',
      app: context.app ? 'Present' : 'Missing',
      rawRequest: context.rawRequest ? 'Present' : 'Missing'
    });
    
    // Return authentication status without requiring authentication
    if (!context.auth) {
      console.log('❌ No authentication context found');
      return { 
        success: false, 
        message: 'No authentication context',
        timestamp: new Date().toISOString()
      };
    }

    console.log('✅ Authentication successful');
    return { 
      success: true, 
      message: 'Authentication working!',
      uid: context.auth.uid,
      timestamp: new Date().toISOString()
    };
  }
);

interface FriendRequestData {
  targetUserId: string;
  currentUserData: {
    name: string;
    username?: string;
    profilePicUrl?: string;
    uid: string;
  };
  targetUserName: string;
  targetUserProfilePicUrl?: string;
}

interface AcceptFriendRequestData {
  requesterUserId: string;
  currentUserData: {
    name: string;
    username?: string;
    profilePicUrl?: string;
    uid: string;
  };
  requesterUserName: string;
  requesterProfilePicUrl?: string;
}

interface FamilyRequestData {
  currentUserId: string;
  memberData: {
    name: string;
    relationship: string;
    nationalId?: string;
    phoneNumber?: string;
    profilePicUrl?: string;
  };
  linkedUserModel?: {
    uid: string;
    name: string;
    profilePicUrl?: string;
  };
}

// Send friend request
export const sendFriendRequest = functions.https.onCall(
  async (data: FriendRequestData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { targetUserId, currentUserData } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Check if users are already friends
      const friendsCheck = await db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friends')
        .doc(targetUserId)
        .get();

      if (friendsCheck.exists) {
        throw new functions.https.HttpsError('already-exists', 'Users are already friends');
      }

      // Check if friend request already exists
      const existingRequest = await db
        .collection('endUsers')
        .doc(targetUserId)
        .collection('friendRequests')
        .doc(currentUserId)
        .get();

      if (existingRequest.exists) {
        throw new functions.https.HttpsError('already-exists', 'Friend request already sent');
      }

      // Create incoming friend request for target user
      const incomingRequestRef = db
        .collection('endUsers')
        .doc(targetUserId)
        .collection('friendRequests')
        .doc(currentUserId);

      batch.set(incomingRequestRef, {
        senderId: currentUserId,
        senderName: currentUserData.name,
        senderUsername: currentUserData.username,
        senderProfilePicUrl: currentUserData.profilePicUrl,
        status: 'pending',
        type: 'incoming',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create outgoing friend request for current user
      const outgoingRequestRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(targetUserId);

      batch.set(outgoingRequestRef, {
        receiverId: targetUserId,
        receiverName: data.targetUserName,
        receiverProfilePicUrl: data.targetUserProfilePicUrl,
        status: 'pending',
        type: 'outgoing',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return { success: true, message: 'Friend request sent successfully' };
    } catch (error) {
      console.error('Error sending friend request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send friend request');
    }
  }
);

// Accept friend request
export const acceptFriendRequest = functions.https.onCall(
  async (data: AcceptFriendRequestData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { requesterUserId, currentUserData } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove friend requests
      const currentUserRequestRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(requesterUserId);

      const requesterRequestRef = db
        .collection('endUsers')
        .doc(requesterUserId)
        .collection('friendRequests')
        .doc(currentUserId);

      batch.delete(currentUserRequestRef);
      batch.delete(requesterRequestRef);

      // Add to friends collections
      const currentUserFriendRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friends')
        .doc(requesterUserId);

      const requesterFriendRef = db
        .collection('endUsers')
        .doc(requesterUserId)
        .collection('friends')
        .doc(currentUserId);

      batch.set(currentUserFriendRef, {
        friendId: requesterUserId,
        friendName: data.requesterUserName,
        friendProfilePicUrl: data.requesterProfilePicUrl,
        friendedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(requesterFriendRef, {
        friendId: currentUserId,
        friendName: currentUserData.name,
        friendProfilePicUrl: currentUserData.profilePicUrl,
        friendedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return { success: true, message: 'Friend request accepted' };
    } catch (error) {
      console.error('Error accepting friend request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to accept friend request');
    }
  }
);

// Decline friend request
export const declineFriendRequest = functions.https.onCall(
  async (data: { requesterUserId: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { requesterUserId } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove friend requests
      const currentUserRequestRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(requesterUserId);

      const requesterRequestRef = db
        .collection('endUsers')
        .doc(requesterUserId)
        .collection('friendRequests')
        .doc(currentUserId);

      batch.delete(currentUserRequestRef);
      batch.delete(requesterRequestRef);

      await batch.commit();

      return { success: true, message: 'Friend request declined' };
    } catch (error) {
      console.error('Error declining friend request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to decline friend request');
    }
  }
);

// Remove friend
export const removeFriend = functions.https.onCall(
  async (data: { friendUserId: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { friendUserId } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove from friends collections
      const currentUserFriendRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendUserId);

      const friendUserFriendRef = db
        .collection('endUsers')
        .doc(friendUserId)
        .collection('friends')
        .doc(currentUserId);

      batch.delete(currentUserFriendRef);
      batch.delete(friendUserFriendRef);

      await batch.commit();

      return { success: true, message: 'Friend removed successfully' };
    } catch (error) {
      console.error('Error removing friend:', error);
      throw new functions.https.HttpsError('internal', 'Failed to remove friend');
    }
  }
);

// Unsend friend request
export const unsendFriendRequest = functions.https.onCall(
  async (data: { targetUserId: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { targetUserId } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove friend requests
      const currentUserRequestRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(targetUserId);

      const targetUserRequestRef = db
        .collection('endUsers')
        .doc(targetUserId)
        .collection('friendRequests')
        .doc(currentUserId);

      batch.delete(currentUserRequestRef);
      batch.delete(targetUserRequestRef);

      await batch.commit();

      return { success: true, message: 'Friend request cancelled' };
    } catch (error) {
      console.error('Error unsending friend request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to cancel friend request');
    }
  }
);

// Add or request family member
export const addOrRequestFamilyMember = functions.https.onCall(
  async (data: FamilyRequestData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { currentUserId, memberData, linkedUserModel } = data;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      if (linkedUserModel) {
        // If linking to an existing user, create family requests
        const familyRequestRef = db
          .collection('endUsers')
          .doc(linkedUserModel.uid)
          .collection('familyRequests')
          .doc(currentUserId);

        batch.set(familyRequestRef, {
          requesterId: currentUserId,
          requesterName: (await db.collection('endUsers').doc(currentUserId).get()).data()?.name,
          relationship: memberData.relationship,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Add to family members collection
      const familyMemberRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('familyMembers')
        .doc();

      batch.set(familyMemberRef, {
        ...memberData,
        linkedUserId: linkedUserModel?.uid,
        status: linkedUserModel ? 'pending' : 'added',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return { 
        success: true, 
        message: linkedUserModel 
          ? 'Family request sent successfully' 
          : 'Family member added successfully' 
      };
    } catch (error) {
      console.error('Error adding family member:', error);
      throw new functions.https.HttpsError('internal', 'Failed to add family member');
    }
  }
);

// Accept family request
export const acceptFamilyRequest = functions.https.onCall(
  async (data: any, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { requesterUserId, currentUserData, requesterName, relationshipProvidedByRequester } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove family request
      const familyRequestRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('familyRequests')
        .doc(requesterUserId);

      batch.delete(familyRequestRef);

      // Add to both users' family members
      const currentUserFamilyRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('familyMembers')
        .doc();

      const requesterFamilyRef = db
        .collection('endUsers')
        .doc(requesterUserId)
        .collection('familyMembers')
        .doc();

      batch.set(currentUserFamilyRef, {
        name: requesterName,
        relationship: relationshipProvidedByRequester,
        linkedUserId: requesterUserId,
        status: 'accepted',
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(requesterFamilyRef, {
        name: currentUserData.name,
        relationship: 'family', // Generic relationship from accepter's side
        linkedUserId: currentUserId,
        status: 'accepted',
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return { success: true, message: 'Family request accepted' };
    } catch (error) {
      console.error('Error accepting family request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to accept family request');
    }
  }
);

// Decline family request
export const declineFamilyRequest = functions.https.onCall(
  async (data: { requesterUserId: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { requesterUserId } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();

      // Remove family request
      await db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('familyRequests')
        .doc(requesterUserId)
        .delete();

      return { success: true, message: 'Family request declined' };
    } catch (error) {
      console.error('Error declining family request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to decline family request');
    }
  }
);

// Remove family member
export const removeFamilyMember = functions.https.onCall(
  async (data: { memberDocId: string; linkedUserId?: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { memberDocId, linkedUserId } = data;
    const currentUserId = context.auth.uid;

    try {
      const db = admin.firestore();
      const batch = db.batch();

      // Remove from current user's family members
      const memberRef = db
        .collection('endUsers')
        .doc(currentUserId)
        .collection('familyMembers')
        .doc(memberDocId);

      batch.delete(memberRef);

      // If it's a linked user, also remove from their family members
      if (linkedUserId) {
        // Find and remove the corresponding family member document
        const linkedUserFamilyQuery = await db
          .collection('endUsers')
          .doc(linkedUserId)
          .collection('familyMembers')
          .where('linkedUserId', '==', currentUserId)
          .get();

        linkedUserFamilyQuery.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
      }

      await batch.commit();

      return { success: true, message: 'Family member removed successfully' };
    } catch (error) {
      console.error('Error removing family member:', error);
      throw new functions.https.HttpsError('internal', 'Failed to remove family member');
    }
  }
); 