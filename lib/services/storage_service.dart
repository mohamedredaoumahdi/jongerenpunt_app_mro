import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload a profile image to Firebase Storage
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Generate a unique filename
      final String fileName = '${userId}_${const Uuid().v4()}.jpg';
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child('profile_images').child(fileName);
      
      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Wait for the upload to complete and get the download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Successfully uploaded profile image. URL: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      throw Exception('Er is een fout opgetreden bij het uploaden van de profielfoto: $e');
    }
  }
  
  // Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Create a reference from the file URL
      final Reference ref = _storage.refFromURL(fileUrl);
      
      // Delete the file
      await ref.delete();
      
      if (kDebugMode) {
        print('Successfully deleted file: $fileUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      throw Exception('Er is een fout opgetreden bij het verwijderen van het bestand: $e');
    }
  }
  
  // Upload a chat attachment (image, document, etc.)
  Future<String> uploadChatAttachment(String userId, File file, String fileType) async {
    try {
      // Generate a unique filename
      final String fileName = '${userId}_${const Uuid().v4()}.$fileType';
      
      // Determine content type based on file extension
      String contentType;
      switch (fileType.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
        case 'docx':
          contentType = 'application/msword';
          break;
        default:
          contentType = 'application/octet-stream';
      }
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child('chat_attachments').child(fileName);
      
      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      
      // Wait for the upload to complete and get the download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading chat attachment: $e');
      }
      throw Exception('Er is een fout opgetreden bij het uploaden van het bestand: $e');
    }
  }
}