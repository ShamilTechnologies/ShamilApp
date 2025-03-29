import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to the specified [destination] path in Firebase Storage.
  /// Returns the download URL if successful, or null on error.
  Future<String?> uploadFile(File file, String destination) async {
    try {
      final ref = _storage.ref(destination);
      final uploadTask = ref.putFile(file);

      // Optionally, you can monitor progress here using uploadTask.snapshotEvents.listen(...)
      await uploadTask.whenComplete(() => null);
      String downloadUrl = await ref.getDownloadURL();

      // Notify listeners that an upload has completed
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  /// Retrieves the download URL for a file stored at the given [path].
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref(path);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      return null;
    }
  }

  /// Deletes the file at the given [path] from Firebase Storage.
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.delete();

      // Notify listeners that a deletion has occurred
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Lists all files under the specified [path] in Firebase Storage.
  Future<ListResult?> listFiles(String path) async {
    try {
      final ref = _storage.ref(path);
      final listResult = await ref.listAll();
      return listResult;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return null;
    }
  }

  /// Updates metadata for the file at the given [path] with provided [metadata].
  /// Returns the updated metadata if successful.
  Future<FullMetadata?> updateMetadata(
      String path, SettableMetadata metadata) async {
    try {
      final ref = _storage.ref(path);
      FullMetadata updatedMetadata = await ref.updateMetadata(metadata);

      // Notify listeners that metadata has been updated
      notifyListeners();
      return updatedMetadata;
    } catch (e) {
      debugPrint('Error updating metadata: $e');
      return null;
    }
  }

  /// Retrieves metadata for the file at the given [path].
  Future<FullMetadata?> getMetadata(String path) async {
    try {
      final ref = _storage.ref(path);
      FullMetadata metadata = await ref.getMetadata();
      return metadata;
    } catch (e) {
      debugPrint('Error getting metadata: $e');
      return null;
    }
  }
}
