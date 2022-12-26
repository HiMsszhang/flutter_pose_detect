import 'classification_result.dart';

class RepetitionCounter {
  // These thresholds can be tuned in conjunction with the Top K values in {@link PoseClassifier}.
  // The default Top K value is 10 so the range here is [0-10].
  static const double _kDefaultEnterThreshold = 6.0;
  static const double _kDefaultExitThreshold = 4.0;

  late final double enterThreshold;
  final double exitThreshold;
  final String className;

  late int numRepeats;
  late bool poseEntered;

  RepetitionCounter({required this.className})
      : enterThreshold = _kDefaultEnterThreshold,
        exitThreshold = _kDefaultExitThreshold {
    numRepeats = 0;
    poseEntered = false;
  }

  /// Adds a new Pose classification result and updates reps for given class.
  ///
  /// @param classificationResult {link ClassificationResult} of class to confidence values.
  /// @return number of reps.
  int addClassificationResult(ClassificationResult classificationResult) {
    double? poseConfidence = classificationResult.getClassConfidence(className);
    // print('className:$className');
    // print('poseConfidence:$poseConfidence');
    // print('poseEntered:$poseEntered');
    if (!poseEntered) {
      poseEntered = poseConfidence! > enterThreshold;
      return numRepeats;
    }
    // print(poseEntered);
    if (poseConfidence! < exitThreshold) {
      numRepeats++;
      poseEntered = false;
    }
    // print(numRepeats);
    return numRepeats;
  }

  String getClassName() => className;

  int getNumRepeats() => numRepeats;
}
