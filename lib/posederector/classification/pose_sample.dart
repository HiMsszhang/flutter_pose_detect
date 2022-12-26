import 'package:common_utils/common_utils.dart';

import 'point_3d.dart';
import 'pose_enbedding.dart';

/// Reads Pose samples from a csv file.
class PoseSample {
  static const String _kTag = "PoseSample";
  static const int _knumLandmarks = 33;
  static const int _kNumDims = 3;

  String name;
  String className;
  List<PointF3D> embedding;

  PoseSample({
    required this.name,
    required this.className,
    required this.embedding,
  }) {
    embedding = PoseEmbedding.getPoseEmbedding(embedding);
  }

  String getName() => name;

  String getClassName() => className;

  List<PointF3D> getEmbedding() => embedding;

  static PoseSample? getPoseSample({required List<String> stringLandmarks}) {
    if (stringLandmarks.length != (_knumLandmarks * _kNumDims) + 2) {
      LogUtil.e("Invalid number of tokens for PoseSample", tag: _kTag);
      return null;
    }
    String name = stringLandmarks[0];
    String className = stringLandmarks[1];
    List<PointF3D> landMarks = [];
    for (var i = 2; i < stringLandmarks.length; i += _kNumDims) {
      try {
        landMarks.add(PointF3D.from(
          double.parse(stringLandmarks[i]),
          double.parse(stringLandmarks[i + 1]),
          double.parse(stringLandmarks[i + 2]),
        ));
      } catch (e) {
        LogUtil.e("Invalid value ${stringLandmarks[i]} for landmark position.", tag: _kTag);
      }
    }
    return PoseSample(name: name, className: className, embedding: landMarks);
  }
}
