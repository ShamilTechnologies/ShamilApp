import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import the content widget
import 'package:shamil_mobile_app/feature/access/widgets/access_code_content.dart';

class AccessCodeView extends StatelessWidget {
  const AccessCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Read AuthBloc state to get user data
    final authState = context.read<AuthBloc>().state;
    String? userId;
    String? userName;
    String? profileImageUrl;

    if (authState is LoginSuccessState) {
      userId = authState.user.uid;
      userName = authState.user.name;
      profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;
      if (profileImageUrl.isEmpty) {
        profileImageUrl = null;
      }
    } else {
      // Handle case where user data isn't available immediately after build
      // This might happen if navigated here before AuthBloc is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // Check if context is still valid
          showGlobalSnackBar(context, "User data not available.",
              isError: true);
          Navigator.maybePop(context); // Pop back if no user data
        }
      });
      // Return a loading indicator or empty container while waiting for pop
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Access Code"),
        elevation: 1,
      ),
      // Use the reusable content widget
      body: AccessCodeContent(
        userId: userId,
        userName: userName,
        profileImageUrl: profileImageUrl,
        isBottomSheet: false, // Indicate it's not in a bottom sheet
      ),
    );
  }
}
