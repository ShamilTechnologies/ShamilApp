import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
// *** Import the icon constants and helper functions ***
import 'package:shamil_mobile_app/core/constants/icon_constants.dart';

Future<String?> showGovernoratesBottomSheet({
  required BuildContext context,
  required List<String> items,
  String title = 'Select Your Governorate',
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor:
        Colors.transparent, // Keep background transparent for custom container
    isScrollControlled: true, // Allows sheet to take more height if needed
    builder: (context) {
      final theme = Theme.of(context); // Get theme context

      return SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white, // Use AppColor
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                // Use theme shadow color or a subtle AppColor
                color: theme.colorScheme.shadow.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum space
            children: [
              // Header row with title and a close button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: getbodyStyle(
                      color: AppColors.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: AppColors.primaryColor),
                    // Use visual density to reduce tap target size slightly if needed
                    // visualDensity: VisualDensity.compact,
                    // padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List of items.
              Flexible(
                // Allows list to scroll if content exceeds available height
                child: ListView.separated(
                  shrinkWrap: true, // Important when nested in Column/Flexible
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    indent: 10, endIndent: 10,
                    // Use a theme color or subtle AppColor for divider
                    color: AppColors.accentColor.withOpacity(0.5),
                    height: 1, // Explicit height for divider
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // *** Get the icon for the current governorate item ***
                    final IconData governorateIcon =
                        getIconForGovernorate(item);

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context)
                          .pop(item), // Return selected item
                      child: Container(
                        // Added Container for consistent padding/decoration if needed later
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            // *** Use the dynamically fetched icon ***
                            Icon(
                              governorateIcon, // Use the fetched icon
                              color: AppColors.primaryColor,
                              size: 22, // Adjust size if needed
                            ),
                            const SizedBox(width: 12), // Spacing
                            Expanded(
                              child: Text(
                                item, // Governorate name
                                style: getbodyStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Optional: Add a trailing check or arrow if needed
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.secondaryColor.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// --- Example Usage (if you wanted to use it for Amenities) ---
// You would need to create kAmenities list similar to kGovernorates
/*
Future<String?> showAmenitiesBottomSheet({
  required BuildContext context,
  required List<String> items, // Should be kAmenities list
  String title = 'Select Amenities',
}) {
  // ... similar structure to showGovernoratesBottomSheet ...
  // Inside itemBuilder:
  // final IconData amenityIcon = getIconForAmenity(item);
  // Use amenityIcon in the Row's Icon widget
  // ...
}
*/
