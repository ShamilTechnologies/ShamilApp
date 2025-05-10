import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import the access content widget and bloc
import 'package:shamil_mobile_app/feature/access/widgets/access_code_content.dart';
import 'package:shamil_mobile_app/feature/access/bloc/access_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

class AccessCodeView extends StatefulWidget {
  const AccessCodeView({super.key});

  @override
  State<AccessCodeView> createState() => _AccessCodeViewState();
}

class _AccessCodeViewState extends State<AccessCodeView> {
  late AccessBloc _accessBloc;
  String? _userId;
  String? _userName;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _accessBloc = AccessBloc();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;

    if (authState is LoginSuccessState) {
      _userId = authState.user.uid;
      _userName = authState.user.name;
      _profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;

      if (_profileImageUrl?.isEmpty ?? true) {
        _profileImageUrl = null;
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      // Handle case where user data isn't available
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showGlobalSnackBar(context, "User data not available.",
              isError: true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.maybePop(context);
            }
          });
        }
      });
    }
  }

  void _resetNFCService() {
    if (_accessBloc.state is NFCErrorState) {
      _accessBloc.add(ResetNFCServiceEvent());
    }
  }

  @override
  void dispose() {
    _accessBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Unable to load user data"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _accessBloc,
      child: BlocListener<AccessBloc, AccessState>(
        listener: (context, state) {
          if (state is NFCSuccessState) {
            if (state.isWriteSuccess) {
              showGlobalSnackBar(
                  context, "Your ID was successfully shared via NFC");
            } else {
              showGlobalSnackBar(context, "NFC tag read successfully!");
            }
          } else if (state is NFCErrorState) {
            showGlobalSnackBar(
                context, state.message ?? "Failed to process NFC",
                isError: true);

            // Auto-recover from errors
            Future.delayed(const Duration(seconds: 2), _resetNFCService);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back,
                  color: AppColors.primaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              "Access Code",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          // Use the reusable content widget
          body: SafeArea(
            child: AccessCodeContent(
              userId: _userId!,
              userName: _userName,
              profileImageUrl: _profileImageUrl,
              isBottomSheet: false, // Indicate it's not in a bottom sheet
            ),
          ),
        ),
      ),
    );
  }
}
