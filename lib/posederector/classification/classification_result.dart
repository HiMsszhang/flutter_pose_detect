import 'dart:math';

class ClassificationResult {
  // For an entry in this map, the key is the class name, and the value is how many times this class
  // appears in the top K nearest neighbors. The value is in range [0, K] and could be a float after
  // EMA smoothing. We use this number to represent the confidence of a pose being in this class.
  late final Map<String, double> classConfidences;

  ClassificationResult() {
    classConfidences = {};
  }

  Set<String> getAllClasses() => classConfidences.keys.toSet();

  double? getClassConfidence(String className) {
    return classConfidences.containsKey(className) ? classConfidences[className] : 0;
  }

  String getMaxConfidenceClass() {
    final values = classConfidences.values.toList();
    final keys = classConfidences.keys.toList();
    return keys[values.indexOf(values.reduce(max))];
  }

  void incrementClassConfidence(String className) {
    classConfidences[className] = classConfidences.containsKey(className) ? classConfidences[className]! + 1 : 1;
  }

  void putClassConfidence(String className, double confidence) {
    classConfidences[className] = confidence;
  }
}
