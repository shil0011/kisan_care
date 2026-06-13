import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final ref = _storage.ref().child('crop_images/$userId/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
