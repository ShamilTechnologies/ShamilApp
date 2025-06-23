# Social Bloc Error Fixes

This document outlines the fixes implemented to resolve the social bloc errors in the ShamilApp.

## Issues Fixed

### 1. Firebase Functions NOT_FOUND Error
**Problem**: The app was calling Firebase Functions that didn't exist, resulting in `[firebase_functions/not-found] NOT_FOUND` errors.

**Root Cause**: Social-related Firebase Functions like `sendFriendRequest`, `acceptFriendRequest`, etc. were not implemented in the backend.

**Solution**: 
- Created `functions/src/social/index.ts` with all required social functions:
  - `sendFriendRequest` - Creates friend requests between users
  - `acceptFriendRequest` - Accepts incoming friend requests
  - `declineFriendRequest` - Declines friend requests
  - `removeFriend` - Removes existing friendships
  - `unsendFriendRequest` - Cancels outgoing friend requests
  - `addOrRequestFamilyMember` - Adds family members or sends family requests
  - `acceptFamilyRequest` - Accepts family connection requests
  - `declineFamilyRequest` - Declines family requests
  - `removeFamilyMember` - Removes family member connections

- Updated `functions/src/index.ts` to export social functions
- Fixed function name mismatches in `lib/feature/social/repository/social_repository.dart`

### 2. SnackBar Layout Error
**Problem**: Multiple "Floating SnackBar presented off screen" errors were occurring due to insufficient vertical space.

**Root Cause**: The SnackBar was configured with `SnackBarBehavior.floating` but there wasn't enough space due to FloatingActionButton and other UI elements.

**Solution**: 
- Modified `lib/core/functions/snackbar_helper.dart` to use `SnackBarBehavior.fixed`
- Added `clearSnackBars()` call to prevent stacking
- Improved SnackBar styling and added an "OK" action button
- Set proper margins and removed custom shape for fixed behavior

## Files Modified

### Frontend (Flutter)
1. `lib/core/functions/snackbar_helper.dart` - Fixed SnackBar layout issues
2. `lib/feature/social/repository/social_repository.dart` - Fixed function name mismatches

### Backend (Firebase Functions)
1. `functions/src/social/index.ts` - **NEW FILE** - Implemented all social functions
2. `functions/src/index.ts` - Added export for social functions

## Deployment Instructions

### Firebase Functions
To deploy the new Firebase Functions, run these commands:

```bash
# Navigate to functions directory
cd functions

# Install dependencies (if not already done)
npm install

# Build the TypeScript files
npm run build

# Deploy to Firebase
firebase deploy --only functions
```

### Alternative if Node.js path issues:
If you encounter Node.js path issues, you can:
1. Ensure Node.js is properly installed and in your PATH
2. Use Firebase CLI directly: `firebase deploy --only functions`
3. Or deploy from Firebase Console by uploading the built functions

## Testing the Fixes

1. **Friend Requests**: Try sending, accepting, declining friend requests
2. **Family Members**: Test adding, accepting, declining family connections
3. **SnackBar**: Verify no more "off screen" errors and proper display
4. **Error Handling**: Confirm proper error messages for failed operations

## Function Structure

Each social function follows this pattern:
- Authentication validation
- Input parameter validation
- Firestore batch operations for data consistency
- Proper error handling with meaningful messages
- Success responses with appropriate feedback

## Database Collections Used

- `endUsers/{userId}/friends/{friendId}` - User friendships
- `endUsers/{userId}/friendRequests/{requesterId}` - Friend requests
- `endUsers/{userId}/familyMembers/{memberId}` - Family member data
- `endUsers/{userId}/familyRequests/{requesterId}` - Family connection requests

## Security Features

- All functions require authentication
- User can only modify their own data
- Proper validation of user relationships
- Batch operations ensure data consistency
- No sensitive data exposure in responses

## Next Steps

1. Deploy the Firebase Functions
2. Test all social functionality end-to-end
3. Monitor Firebase Function logs for any issues
4. Consider adding rate limiting for spam prevention
5. Add comprehensive error tracking and analytics 