import 'package:flutter/material.dart';
// For CupertinoIcons if needed

// --- Governorate Icons ---

// It's less common to have specific icons for each governorate,
// often a single location icon is used. But mapping if needed:
const Map<String, IconData> kGovernorateIcons = {
  'Cairo': Icons.location_city_rounded,
  'Giza': Icons.location_city_outlined, // Example variation
  'Alexandria': Icons.location_on_rounded,
  'Qalyubia': Icons.location_on_outlined,
  'Sharqia': Icons.location_on_outlined,
  'Dakahlia': Icons.location_on_outlined,
  'Beheira': Icons.location_on_outlined,
  'Kafr El Sheikh': Icons.location_on_outlined,
  'Gharbia': Icons.location_on_outlined,
  'Monufia': Icons.location_on_outlined,
  'Damietta': Icons.location_on_outlined,
  'Port Said': Icons.anchor_rounded, // Coastal city example
  'Ismailia': Icons.location_on_outlined,
  'Suez': Icons.directions_boat_filled_outlined, // Canal example
  'North Sinai': Icons.landscape_outlined,
  'South Sinai': Icons.surfing_rounded, // Beach/Tourism example
  'Beni Suef': Icons.location_on_outlined,
  'Faiyum': Icons.wb_sunny_outlined, // Oasis example
  'Minya': Icons.location_on_outlined,
  'Asyut': Icons.location_on_outlined,
  'Sohag': Icons.location_on_outlined,
  'Qena': Icons.location_on_outlined,
  'Luxor': Icons.account_balance_rounded, // Historical site example
  'Aswan': Icons.sailing_rounded, // Nile example
  'Red Sea': Icons.waves_rounded, // Sea example
  'New Valley': Icons.agriculture_outlined, // Example
  'Matrouh': Icons.beach_access_rounded, // Example
  // Default for unmatched governorates
  '_default': Icons.location_on_rounded,
};

IconData getIconForGovernorate(String governorateName) {
  return kGovernorateIcons[governorateName] ?? kGovernorateIcons['_default']!;
}


// --- Amenity Icons ---

const Map<String, IconData> kAmenityIcons = {
  'WiFi': Icons.wifi_rounded,
  'Parking': Icons.local_parking_rounded,
  'Air Conditioning': Icons.ac_unit_rounded,
  'Waiting Area': Icons.chair_rounded,
  'Restrooms': Icons.wc_rounded,
  'Cafe': Icons.local_cafe_rounded,
  'Lockers': Icons.lock_outline_rounded,
  'Showers': Icons.shower_rounded,
  'Wheelchair Accessible': Icons.accessible_rounded,
  'Prayer Room': Icons.mosque_rounded, // Or appropriate icon
  'Music System': Icons.music_note_rounded,
  'TV Screens': Icons.tv_rounded,
  'Water Dispenser': Icons.local_drink_rounded,
  'Changing Rooms': Icons.checkroom_rounded,
  // Default for unmatched amenities
  '_default': Icons.check_box_outline_blank_rounded, // Placeholder
};

IconData getIconForAmenity(String amenityName) {
  // Handle potential case variations from backend
  String keyToFind = kAmenityIcons.keys.firstWhere(
        (k) => k.toLowerCase() == amenityName.toLowerCase(),
        orElse: () => '_default', // Use default if no case-insensitive match
  );
  return kAmenityIcons[keyToFind]!;
}


// --- Business Category Icons ---

const Map<String, IconData> kBusinessCategoryIcons = {
  'Fitness': Icons.fitness_center_rounded,
  'Sports': Icons.sports_soccer_rounded, // General sports
  'Entertainment': Icons.local_play_rounded,
  'Events': Icons.event_rounded,
  'Health': Icons.health_and_safety_outlined, // Or local_hospital
  'Education': Icons.school_rounded,
  'Beauty': Icons.spa_rounded, // Or face_retouching_natural
  'Retail': Icons.store_mall_directory_rounded,
  'Consulting': Icons.groups_rounded,
  'Restaurant': Icons.restaurant_rounded,
  'Other': Icons.category_rounded,
  // Add more specific icons if needed (e.g., Padel: Icons.sports_tennis)
  // Consider mapping subcategories if your backend provides them
  '_default': Icons.business_center_rounded, // Default business icon
};

IconData getIconForCategory(String categoryName) {
  // Handle potential case variations and partial matches if needed
   String keyToFind = kBusinessCategoryIcons.keys.firstWhere(
        (k) => k.toLowerCase() == categoryName.toLowerCase(),
        orElse: () {
           // Basic check if categoryName *contains* a key (e.g., "Sports Club" contains "Sports")
           for (String key in kBusinessCategoryIcons.keys) {
              if (key != '_default' && categoryName.toLowerCase().contains(key.toLowerCase())) {
                 return key;
              }
           }
           return '_default'; // Use default if no match
        },
   );
  return kBusinessCategoryIcons[keyToFind]!;
}