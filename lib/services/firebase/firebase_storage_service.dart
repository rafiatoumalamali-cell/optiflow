import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Uploads a product image and returns the download URL.
  Future<String> uploadProductImage({
    required String businessId,
    required File imageFile,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('products')
          .child(fileName);

      // Check if file exists
      if (!await imageFile.exists()) {
        throw 'Image file does not exist';
      }

      // Get file size to ensure it's not too large
      final int fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        throw 'Image file is too large. Maximum size is 5MB.';
      }

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': 'optiflow_app',
            'business_id': businessId,
            'upload_time': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      
      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      throw 'Failed to upload product image: $e';
    }
  }

  /// Uploads a delivery proof photo and returns the download URL.
  Future<String> uploadDeliveryProof({
    required String routeId,
    required File imageFile,
  }) async {
    try {
      final String fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('routes')
          .child(routeId)
          .child('proofs')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload delivery proof: $e';
    }
  }

  /// Uploads signature bytes and returns the download URL.
  Future<String> uploadSignature({
    required String routeId,
    required Uint8List signatureBytes,
  }) async {
    try {
      final String fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference ref = _storage
          .ref()
          .child('routes')
          .child(routeId)
          .child('signatures')
          .child(fileName);

      final UploadTask uploadTask = ref.putData(
        signatureBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload signature: $e';
    }
  }
}
