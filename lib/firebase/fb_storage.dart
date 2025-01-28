import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FbStorage {
  static Future<String> uploadImage(String path) async {
    final storage = FirebaseStorage.instance;
    final imageFile = File(path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final reference = storage.ref().child('images/$fileName');

    final uploadTask = reference.putFile(imageFile);

    // Display progress indicator (optional)
    final taskSnapshot = await uploadTask.whenComplete(() => null);

    // Get the download URL
    final url = await taskSnapshot.ref.getDownloadURL();

    return url;
  }

  static Future<String?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return pickedFile.path;
    } else {
      return null; // User canceled or failed to pick an image
    }
  }
}
