import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data' show Uint8List;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String nonFilename,
  }) async {
    try {
      final ref = _storage.ref().child('products/$nonFilename.jpg');
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
