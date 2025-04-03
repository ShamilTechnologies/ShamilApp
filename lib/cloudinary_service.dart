import 'dart:convert';
import 'dart:io';

// Keep for potential future use if signed requests are needed (on backend!)
import 'package:http/http.dart' as http;
import 'package:shamil_mobile_app/secrets/cloudinary_config.dart'; // Ensure this path is correct

class CloudinaryService {
  // Load configuration once using the config class
  static final Map<String, String> _config = _loadConfig();
  static final String? cloudName = _config['cloudName'];
  static final String? apiKey = _config['apiKey'];
  // ** API Secret should NOT be stored/used directly in the client app **
  // static final String? apiSecret = _config['apiSecret'];

  // For unsigned uploads via upload presets (safer for client-side)
  // Ensure 'ml_default' is your actual unsigned upload preset name in Cloudinary settings
  static const String uploadPreset = 'ml_default';

  // Helper function to load config and handle potential errors
  static Map<String, String> _loadConfig() {
    try {
      // Ensure CloudinaryConfig is initialized if needed (e.g., dotenv loaded)
      return CloudinaryConfig.parseCloudinaryUrl();
    } catch (e) {
      print("CRITICAL ERROR: Failed to load Cloudinary config: $e");
      // Return empty map or throw to prevent service usage without config
      return {};
      // Or uncomment below to throw:
      // throw Exception("CloudinaryService: Failed to initialize configuration.");
    }
  }

  /// Uploads a file to Cloudinary using an unsigned upload preset.
  /// Optionally, specify a [folder] to organize uploads.
  /// Returns the secure URL of the uploaded file, or null on failure.
  static Future<String?> uploadFile(File file, {String folder = ''}) async {
    // Ensure configuration was loaded successfully
    if (cloudName == null || cloudName!.isEmpty) {
       print("Cloudinary Error: Cloud name is not configured.");
       return null;
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    print("Cloudinary: Uploading to $url (preset: $uploadPreset, folder: $folder)");

    try {
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString(); // Read response body regardless of status

      if (response.statusCode >= 200 && response.statusCode < 300) { // Check for 2xx status codes
        final jsonData = json.decode(responseBody);
        final secureUrl = jsonData['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
           print("Cloudinary: Upload successful. URL: $secureUrl");
           return secureUrl;
        } else {
           print("Cloudinary upload warning: Status code ${response.statusCode} but secure_url missing in response: $responseBody");
           return null;
        }
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Response body: $responseBody');
        return null;
      }
    } catch (e, s) {
      print('Cloudinary: Error uploading file: $e\n$s');
      return null;
    }
  }

  /// **Client-side Signed Deletion REMOVED**
  ///
  /// Deleting resources requires your API Secret, which should NEVER be included
  /// directly in a client-side application (like a mobile app).
  ///
  /// **Implement deletion securely on your backend server (e.g., using a Cloud Function):**
  /// 1. Your app sends a request to your backend endpoint (e.g., `/deleteImage`).
  /// 2. The request includes the public_id of the image to delete and authentication info (e.g., user token).
  /// 3. Your backend verifies the user's permission to delete the image.
  /// 4. Your backend makes a SIGNED request to the Cloudinary Admin API's destroy endpoint
  ///    using your API Key and API Secret (securely stored on the server).
  // static Future<bool> deleteFile(...) { /* REMOVED */ }


  /// Retrieves details of a resource from Cloudinary using its public ID.
  /// Note: This typically uses Cloudinary's public API endpoints. Access might
  /// depend on your Cloudinary account's security settings.
  /// For administrative tasks or sensitive data, perform such actions on your secure backend.
  static Future<Map<String, dynamic>?> getResource(String publicId,
      {String resourceType = 'image'}) async {

     if (cloudName == null || cloudName!.isEmpty || apiKey == null || apiKey!.isEmpty) {
       print("Cloudinary Error: Configuration missing for getResource.");
       return null;
    }
    // Note: Authentication (API Key) might be needed depending on resource type and settings.
    // This example uses a basic resource endpoint. The Admin API requires signatures.
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/$resourceType/upload/$publicId?api_key=$apiKey');
        // Adding API key might be necessary for some resource fetching

    print("Cloudinary: Fetching resource details for publicId: $publicId");

    try {
      // Basic GET request - add authentication headers if needed by your settings
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Cloudinary: Resource details fetched successfully.");
        return data as Map<String, dynamic>?;
      } else {
        print('Cloudinary: Failed to fetch resource details. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('Cloudinary: Error fetching resource: $e\n$s');
      return null;
    }
  }
}
