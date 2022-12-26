import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_detect_poses/posederector/classification/classification_result.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'e_m_a_smoothing.dart';
import 'pose_classsifier.dart';
import 'pose_sample.dart';
import 'repetition_counter.dart';
import 'utils.dart';

class PoseClassifierProcessor {
  static const String _kPoseSamplesFile = 'assets/pose/fitness_pose_samples.csv';

  // Specify classes for which we want rep counting.
  // These are the labels in the given {@code POSE_SAMPLES_FILE}. You can set your own class labels
  // for your pose samples.
  static const String _kPushupsClass = 'pushups_down';
  static const String _kSquatsClass = 'squats_down';
  static final List<String> _kPoseClass = [_kPushupsClass, _kSquatsClass];

  late EMASmoothing _emaSmoothing;
  late List<RepetitionCounter> _repCounters;
  late PoseClassifier _poseClassifier;
  late String _lastRepResult;

  PoseClassifierProcessor() {
    _emaSmoothing = EMASmoothing();
    _repCounters = [];
    _lastRepResult = '';
    _repCounters = _getRepCounters();
    _loadPoseSamples().then((value) => _poseClassifier = value);
  }

  Future<PoseClassifier> _loadPoseSamples() async {
    List<PoseSample> poseSamples = [];
    final myData = await rootBundle.loadString(_kPoseSamplesFile);
    var csvT = myData.replaceAll(RegExp(r"\n"), ',');
    csvT = csvT.substring(0, csvT.lastIndexOf(','));
    final lines = splitList(csvT.split(','), 101);
    for (var line in lines) {
      PoseSample? poseSample = PoseSample.getPoseSample(stringLandmarks: line);
      if (poseSample != null) {
        poseSamples.add(poseSample);
      }
    }
    return PoseClassifier(poseSamples: poseSamples);
  }

  List<RepetitionCounter> _getRepCounters() {
    List<RepetitionCounter> repCounters = [];
    for (String className in _kPoseClass) {
      repCounters.add(RepetitionCounter(className: className));
    }
    return repCounters;
  }

  /// Given a new [Pose] input, returns a list of formatted  [String]s with Pose
  /// classification results.
  ///
  /// <p>Currently it returns up to 2 strings as following:
  /// 0: PoseClass : X reps
  /// 1: PoseClass : [0.0-1.0] confidence
  List<String> getPoseResult(Pose pose, Size inputImageSize) {
    List<String> result = [];
    ClassificationResult classification = _poseClassifier.classify(pose, inputImageSize);
    // Feed pose to smoothing even if no pose found.
    classification = _emaSmoothing.getSmoothedResult(classification);
    // Return early without updating repCounter if no pose found.
    if (pose.landmarks.isEmpty) {
      result.add(_lastRepResult);
      return result;
    }
    for (RepetitionCounter repCounter in _repCounters) {
      int repsBefore = repCounter.getNumRepeats();
      int repsAfter = repCounter.addClassificationResult(classification);
      // print('repsBefore:$repsBefore');
      // print('repsAfter:$repsAfter');
      if (repsAfter > repsBefore) {
        //这里做计数成功的反馈
        _lastRepResult = '${repCounter.getClassName()}:$repsAfter';
        break;
      }
    }
    result.add(_lastRepResult);

    // Add maxConfidence class of current frame to result if pose is found.
    if (pose.landmarks.isNotEmpty) {
      String maxConfidenceClass = classification.getMaxConfidenceClass();
      String maxConfidenceClassResult = '$maxConfidenceClass:${(classification.getClassConfidence(maxConfidenceClass)! / _poseClassifier.confidenceRange()).toStringAsFixed(3)} 置信度';
      result.add(maxConfidenceClassResult);
    }
    return result;
  }
}
