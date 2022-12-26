import 'dart:collection';

import 'classification_result.dart';

/// Runs EMA smoothing over a window with given stream of pose classification results.
class EMASmoothing {
  static const int _kDefaultWindowsSize = 10;
  static const double _kDefaultAlpha = 0.2;
  static const int _kResetThreshold = 150;
  int _lastInputMs = 0;
  final int windowSize;
  final double alpha;

  /// This is a window of {@link ClassificationResult}s as outputted by the {@link PoseClassifier}.
  /// We run smoothing over this window of size {@link windowSize}.
  final Queue<ClassificationResult> window;

  EMASmoothing()
      : windowSize = _kDefaultWindowsSize,
        alpha = _kDefaultAlpha,
        window = ListQueue(_kDefaultWindowsSize);

  ClassificationResult getSmoothedResult(ClassificationResult classificationResult) {
    // Resets memory if the input is too far away from the previous one in time.
    int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastInputMs > _kResetThreshold) {
      window.clear();
    }
    _lastInputMs = nowMs;

    // If we are at window size, remove the last (oldest) result.
    if (window.length == windowSize) {
      window.removeLast();
    }
    // Insert at the beginning of the window.
    window.addFirst(classificationResult);

    Set allClasses = {};
    for (ClassificationResult result in window) {
      allClasses.addAll(result.getAllClasses());
    }
    // print('allClasses:${allClasses.toList()}');
    ClassificationResult smoothedResult = ClassificationResult();

    for (String className in allClasses) {
      double factor = 1;
      double topSum = 0;
      double bottomSum = 0;
      for (ClassificationResult result in window) {
        double? value = result.getClassConfidence(className);

        topSum += factor * value!;
        bottomSum += factor;

        factor = factor * (1.0 - alpha);
      }
      smoothedResult.putClassConfidence(className, topSum / bottomSum);
    }

    return smoothedResult;
  }
}
