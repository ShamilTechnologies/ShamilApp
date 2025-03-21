import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/home/home_view.dart';

class OneMoreStepScreen extends StatefulWidget {
  const OneMoreStepScreen({super.key});

  @override
  State<OneMoreStepScreen> createState() => _OneMoreStepScreenState();
}

class _OneMoreStepScreenState extends State<OneMoreStepScreen> {
  File? _profilePic;
  File? _idFront;
  File? _idBack;
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfilePic() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profilePic = File(pickedImage.path);
      });
    }
  }

  Future<void> _scanIdFront() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _idFront = File(pickedImage.path);
      });
    }
  }

  Future<void> _scanIdBack() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _idBack = File(pickedImage.path);
      });
    }
  }

  /// Dispatches an UploadIdEvent to the AuthBloc which will now handle file uploads via Cloudinary.
  void _uploadFiles() {
    if (_profilePic != null && _idFront != null && _idBack != null) {
      context.read<AuthBloc>().add(
            UploadIdEvent(
              profilePic: _profilePic!,
              idFront: _idFront!,
              idBack: _idBack!,
            ),
          );
    }
  }

  /// Validates the current step and either moves to the next step or triggers the upload.
  void _continue() {
    if (_currentStep == 0) {
      if (_profilePic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload your profile picture.")),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_idFront == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload the front of your ID.")),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_idBack == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload the back of your ID.")),
        );
        return;
      }
      _uploadFiles();
    }
  }

  /// Returns to the previous step.
  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  /// Skips the upload process and navigates directly to HomeScreen.
  void _skip() {
    pushReplacement(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UploadIdLoadingState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploading files to Cloudinary...")),
          );
        } else if (state is UploadIdSuccessState) {
          pushReplacement(context, const HomeScreen());
        } else if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${state.message}")),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("One More Step!"),
          centerTitle: true,
        ),
        body: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          onStepContinue: _continue,
          onStepCancel: _back,
          steps: [
            Step(
              title: const Text("Profile"),
              content: ModernUploadField(
                title: "Profile Picture",
                description: "Upload a clear headshot.",
                file: _profilePic,
                onTap: _pickProfilePic,
              ),
              isActive: _currentStep >= 0,
              state:
                  _profilePic != null ? StepState.complete : StepState.editing,
            ),
            Step(
              title: const Text("ID Front"),
              content: ModernUploadField(
                title: "ID Front",
                description: "Capture the front side of your ID.",
                file: _idFront,
                onTap: _scanIdFront,
              ),
              isActive: _currentStep >= 1,
              state: _idFront != null ? StepState.complete : StepState.editing,
            ),
            Step(
              title: const Text("ID Back"),
              content: ModernUploadField(
                title: "ID Back",
                description: "Capture the back side of your ID.",
                file: _idBack,
                onTap: _scanIdBack,
              ),
              isActive: _currentStep >= 2,
              state: _idBack != null ? StepState.complete : StepState.editing,
            ),
          ],
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep != 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text("Back",
                          style: getbodyStyle(color: AppColors.primaryColor)),
                    ),
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentStep == 2 ? "Finish" : "Continue",
                      style: getbodyStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: _skip,
            child: Text(
              "Skip for now",
              style: getbodyStyle(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernUploadField extends StatelessWidget {
  final String title;
  final String description;
  final File? file;
  final VoidCallback onTap;

  const ModernUploadField({
    super.key,
    required this.title,
    required this.description,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 150,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: file == null
                    ? const Icon(Icons.cloud_upload,
                        size: 30, color: AppColors.primaryColor)
                    : const Icon(Icons.check_circle,
                        size: 30, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: getbodyStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: getbodyStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 14)),
                  ],
                ),
              ),
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
