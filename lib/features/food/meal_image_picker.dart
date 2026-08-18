import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class MealImage {
  const MealImage({required this.bytes, required this.fileName, this.mimeType});

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}

abstract interface class MealImagePicker {
  bool get isSupported;

  Future<MealImage?> takePhoto();

  Future<MealImage?> chooseFromGallery();

  Future<MealImage?> retrieveLostPhoto();
}

class DeviceMealImagePicker implements MealImagePicker {
  DeviceMealImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<MealImage?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
      maxWidth: 1600,
      requestFullMetadata: false,
    );

    return file == null ? null : _readImage(file);
  }

  @override
  Future<MealImage?> chooseFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      requestFullMetadata: false,
    );

    return file == null ? null : _readImage(file);
  }

  @override
  Future<MealImage?> retrieveLostPhoto() async {
    if (!isSupported || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null) throw response.exception!;

    final file = response.file;
    return file == null ? null : _readImage(file);
  }

  Future<MealImage> _readImage(XFile file) async {
    return MealImage(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }
}
