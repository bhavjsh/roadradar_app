import 'dart:math';
import 'package:image_picker/image_picker.dart';

class MLService {
  // Pretend this is a real ML model call
  Future<String> verifyImage(XFile image) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network/model delay
    // Randomly pretend to verify
    final verdicts = [
      'Verified: Hazard detected',
      'Verified: No hazard detected',
      'Unclear: Please retake photo',
      'Verified: Needs manual review',
    ];
    return verdicts[Random().nextInt(verdicts.length)];
  }
}

final mlService = MLService();
