import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:gap/gap.dart';

class SharingSettingsSection extends StatefulWidget {
  final OptionsConfigurationState state;

  const SharingSettingsSection({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  State<SharingSettingsSection> createState() => _SharingSettingsSectionState();
}

class _SharingSettingsSectionState extends State<SharingSettingsSection> {
  final TextEditingController _emailController = TextEditingController();
  final List<String> _emails = [];

  @override
  void initState() {
    super.initState();
    // Initialize with any existing additional emails
    if (widget.state.additionalEmails != null) {
      _emails.addAll(widget.state.additionalEmails!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.share,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Sharing Options",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Sharing toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Share Booking Details",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              subtitle: Text(
                "Send booking information via email",
                style: AppTextStyle.getSmallStyle(
                  color: Colors.grey,
                ),
              ),
              value: widget.state.enableSharing,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                context.read<OptionsConfigurationBloc>().add(
                      UpdateSharingSettings(
                        enableSharing: value,
                        shareWithAttendees: widget.state.shareWithAttendees,
                        additionalEmails: _emails.isEmpty ? null : _emails,
                      ),
                    );
              },
            ),

            if (widget.state.enableSharing) ...[
              const Divider(),
              const Gap(8),

              // Share with attendees toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Share with Attendees",
                  style: AppTextStyle.getTitleStyle(fontSize: 14),
                ),
                subtitle: Text(
                  "Automatically share with all added attendees",
                  style: AppTextStyle.getSmallStyle(
                    color: Colors.grey,
                  ),
                ),
                value: widget.state.shareWithAttendees,
                activeColor: AppColors.primaryColor,
                onChanged: (value) {
                  context.read<OptionsConfigurationBloc>().add(
                        UpdateSharingSettings(
                          enableSharing: widget.state.enableSharing,
                          shareWithAttendees: value,
                          additionalEmails: _emails.isEmpty ? null : _emails,
                        ),
                      );
                },
              ),

              const Gap(12),

              // Additional emails
              Text(
                "Additional Email Recipients",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              const Gap(8),

              // Email input field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Enter email address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addEmail,
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: 80,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _addEmail(_emailController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Add"),
                    ),
                  ),
                ],
              ),

              const Gap(8),

              // Emails chips
              if (_emails.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _emails
                      .map((email) => Chip(
                            label: Text(email),
                            deleteIcon: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 18,
                            ),
                            onDeleted: () => _removeEmail(email),
                            backgroundColor: Colors.grey.withOpacity(0.1),
                          ))
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _addEmail(String email) {
    if (email.trim().isEmpty) return;

    // Simple email validation
    final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (!_emails.contains(email)) {
        _emails.add(email);
        _emailController.clear();

        // Update bloc state
        context.read<OptionsConfigurationBloc>().add(
              UpdateSharingSettings(
                enableSharing: widget.state.enableSharing,
                shareWithAttendees: widget.state.shareWithAttendees,
                additionalEmails: _emails,
              ),
            );
      }
    });
  }

  void _removeEmail(String email) {
    setState(() {
      _emails.remove(email);

      // Update bloc state
      context.read<OptionsConfigurationBloc>().add(
            UpdateSharingSettings(
              enableSharing: widget.state.enableSharing,
              shareWithAttendees: widget.state.shareWithAttendees,
              additionalEmails: _emails.isEmpty ? null : _emails,
            ),
          );
    });
  }
}
 