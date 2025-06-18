// lib/core/utils/bottom_sheets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:gap/gap.dart'; // For spacing
import 'package:shamil_mobile_app/core/constants/app_constants.dart'; // Assuming kGovernorates is here
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // Assuming kGovernorateIcons and getIconForGovernorate are here
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Your AppColors
import 'package:shamil_mobile_app/core/utils/text_style.dart'
    as app_text_style; // Your AppTextStyles

/// Displays a modal bottom sheet for selecting a governorate.
///
/// Returns the selected governorate [String] or `null` if no selection is made.
Future<String?> showGovernoratesBottomSheet(
  BuildContext context,
  String? currentSelectedGovernorate,
) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // Allows the sheet to take up more height
    backgroundColor: Colors.transparent, // Make default background transparent
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          String searchQuery = "";
          final List<String> filteredGovernorates = kGovernorates
              .where((gov) =>
                  gov.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.6, // Start at 60% of screen height
            minChildSize: 0.4, // Minimum 40%
            maxChildSize: 0.85, // Maximum 85%
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors
                      .bottomSheetBackground, // Use new bottom sheet background color
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        "Select Governorate",
                        style: app_text_style.getTitleStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search governorate...",
                          hintStyle: app_text_style.getbodyStyle(
                              color: AppColors.secondaryText.withOpacity(0.7)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.secondaryText.withOpacity(0.7)),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                        ),
                        style: app_text_style.getbodyStyle(
                            color: AppColors.primaryText),
                      ),
                    ),
                    // Governorate List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: filteredGovernorates.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey[200],
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final governorate = filteredGovernorates[index];
                          final bool isSelected =
                              governorate == currentSelectedGovernorate;
                          return ListTile(
                            leading: Icon(
                              getIconForGovernorate(governorate),
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryText.withOpacity(0.8),
                              size: 22,
                            ),
                            title: Text(
                              governorate,
                              style: app_text_style.getbodyStyle(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    color: AppColors.primaryColor, size: 20)
                                : null,
                            tileColor: isSelected
                                ? AppColors.primaryColor.withOpacity(0.05)
                                : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(sheetContext, governorate);
                            },
                          );
                        },
                      ),
                    ),
                    const Gap(8), // For bottom padding inside the sheet
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// Example of how kGovernorates might be defined in app_constants.dart
// const List<String> kGovernorates = [
//   "Cairo", "Giza", "Alexandria", "Qalyubia", "Sharqia", "Dakahlia",
//   "Beheira", "Kafr El Sheikh", "Gharbia", "Monufia", "Damietta",
//   "Port Said", "Ismailia", "Suez", "North Sinai", "South Sinai",
//   "Beni Suef", "Faiyum", "Minya", "Asyut", "Sohag", "Qena",
//   "Luxor", "Aswan", "Red Sea", "New Valley", "Matrouh",
// ];

// Example of how kGovernorateIcons and getIconForGovernorate might be defined in icon_constants.dart
// const Map<String, IconData> kGovernorateIcons = {
//   'Cairo': Icons.location_city_rounded,
//   'Giza': Icons.account_balance_outlined, // Pyramids
//   'Alexandria': Icons.waves_rounded, // Sea
//   // ... other mappings
//   '_default': Icons.map_outlined,
// };
//
// IconData getIconForGovernorate(String governorateName) {
//   return kGovernorateIcons[governorateName] ?? kGovernorateIcons['_default']!;
// }
