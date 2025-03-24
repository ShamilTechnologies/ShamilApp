import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';

/// Animates text by "typing" one letter at a time.
class SmoothTypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration letterDelay;

  const SmoothTypingText({
    super.key,
    required this.text,
    required this.style,
    this.letterDelay = const Duration(milliseconds: 100),
  });

  @override
  _SmoothTypingTextState createState() => _SmoothTypingTextState();
}

class _SmoothTypingTextState extends State<SmoothTypingText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant SmoothTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetTyping();
      _startTyping();
    }
  }

  void _resetTyping() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = "";
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.letterDelay, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
        });
        _currentIndex++;
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}

/// A modern upload field with icon, title, description, and optional image preview.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentColor.withOpacity(0.3)),
        ),
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
                  Text(
                    title,
                    style: getbodyStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: getbodyStyle(
                      color: AppColors.secondaryColor,
                      fontSize: 14,
                    ),
                  ),
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
    );
  }
}

/// OneMoreStepScreen: Handles profile picture selection and ID scanning using camera or gallery.
class OneMoreStepScreen extends StatefulWidget {
  const OneMoreStepScreen({super.key});

  @override
  State<OneMoreStepScreen> createState() => _OneMoreStepScreenState();
}

class _OneMoreStepScreenState extends State<OneMoreStepScreen>
    with TickerProviderStateMixin {
  File? _profilePic;
  File? _idFront;
  File? _idBack;
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Displays a modern bottom sheet for image source selection using our theme.
  Future<ImageSource?> _showImageSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color:AppColors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Image Source',
                style: getbodyStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text('Camera',
                    style: getbodyStyle(color: AppColors.primaryColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo, color: AppColors.primaryColor),
                title: Text('Gallery',
                    style: getbodyStyle(color: AppColors.primaryColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Picks an image from the chosen source.
  Future<void> _pickImage() async {
    final source = await _showImageSourceSelector();
    if (source != null) {
      final pickedImage = await _picker.pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          // Update file based on current step.
          if (_currentStep == 0) {
            _profilePic = File(pickedImage.path);
          } else if (_currentStep == 1) {
            _idFront = File(pickedImage.path);
          } else if (_currentStep == 2) {
            _idBack = File(pickedImage.path);
          }
        });
      } else {
        showGlobalSnackBar(context, "Image capture cancelled.");
      }
    }
  }

  Future<void> _scanIdFront() async {
    // For ID scanning steps, we use the same _pickImage method.
    await _pickImage();
  }

  Future<void> _scanIdBack() async {
    // For ID scanning steps, we use the same _pickImage method.
    await _pickImage();
  }

  /// Dispatches an event to upload the files.
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

  /// Validates the current step and moves forward or triggers file upload.
  void _continue() {
    if (_currentStep == 0) {
      if (_profilePic == null) {
        showGlobalSnackBar(context, "Please upload your profile picture.");
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_idFront == null) {
        showGlobalSnackBar(context, "Please scan the front of your ID.");
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_idBack == null) {
        showGlobalSnackBar(context, "Please scan the back of your ID.");
        return;
      }
      _uploadFiles();
    }
  }

  /// Moves back one step.
  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  /// Skips the upload process.
  void _skip() {
    pushReplacement(context, const ExploreScreen());
  }

  /// Returns a custom icon for each step.
  Widget _buildStepIcon(int step, bool isActive) {
    IconData iconData;
    switch (step) {
      case 0:
        iconData = Icons.person;
        break;
      case 1:
        iconData = Icons.document_scanner;
        break;
      case 2:
        iconData = Icons.document_scanner_outlined;
        break;
      default:
        iconData = Icons.info;
    }
    return Icon(
      iconData,
      color: isActive ? Colors.white : AppColors.primaryColor,
      size: 20,
    );
  }

  /// Builds a custom horizontal step indicator.
  Widget _buildCustomStepper() {
    List<Widget> indicators = [];
    for (int i = 0; i < 3; i++) {
      bool isCompleted = i < _currentStep;
      bool isCurrent = i == _currentStep;
      bool isActive = isCompleted || isCurrent;
      Widget circle = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.primaryColor : Colors.white,
          border: Border.all(color: AppColors.primaryColor, width: 2),
        ),
        child: Center(child: _buildStepIcon(i, isActive)),
      );
      indicators.add(circle);
      if (i < 2) {
        indicators.add(
          Expanded(
            child: Container(
              height: 2,
              color: i < _currentStep ? AppColors.primaryColor : Colors.grey.shade300,
            ),
          ),
        );
      }
    }
    return Row(children: indicators);
  }

  /// Returns the content widget for the current step.
  Widget _buildCurrentStepContent() {
    if (_currentStep == 0) {
      return ModernUploadField(
        title: "Profile Picture",
        description: "Tap to capture or select a headshot.",
        file: _profilePic,
        onTap: _pickImage,
      );
    } else if (_currentStep == 1) {
      return ModernUploadField(
        title: "ID Front",
        description: "Tap to scan the front of your ID.",
        file: _idFront,
        onTap: _scanIdFront,
      );
    } else {
      return ModernUploadField(
        title: "ID Back",
        description: "Tap to scan the back of your ID.",
        file: _idBack,
        onTap: _scanIdBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UploadIdLoadingState) {
          showGlobalSnackBar(context, "Please wait....");
        } else if (state is UploadIdSuccessState) {
          pushReplacement(context, const ExploreScreen());
        } else if (state is AuthErrorState) {
          showGlobalSnackBar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SmoothTypingText(
                    text: "Few More Steps",
                    style: getbodyStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomStepper(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildCurrentStepContent()),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: _back,
                          child: Text(
                            "Back",
                            style: getbodyStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      CustomButton(
                        width: MediaQuery.of(context).size.width * 0.6,
                        onPressed: _continue,
                        text: _currentStep == 2 ? "Finish" : "Continue",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
