import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptPicker {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> fromCamera() async {
    final result = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    return result != null ? File(result.path) : null;
  }

  Future<File?> fromGallery() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return result != null ? File(result.path) : null;
  }

  Future<File?> fromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
    );
    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return null;
    }
    return File(result.files.single.path!);
  }
}

final receiptPickerProvider = Provider<ReceiptPicker>((_) => ReceiptPicker());
