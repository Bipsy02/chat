import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageHandler {
  final ImagePicker _picker = ImagePicker();

  // Method to pick an image and convert it to a File
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Method to encode the image to Base64 string
  Future<String?> encodeImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error encoding image: $e");
      return null;
    }
  }

  // Method to decode the Base64 string back to image
  Future<File?> decodeBase64ToImage(String base64Image, String filePath) async {
    try {
      List<int> imageBytes = base64Decode(base64Image);
      File file = File(filePath);
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }
}