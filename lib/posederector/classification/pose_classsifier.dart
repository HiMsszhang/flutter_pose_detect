import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_detect_poses/posederector/classification/utils.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'classification_result.dart';
import 'point_3d.dart';
import 'pose_enbedding.dart';
import 'pose_sample.dart';

class PoseClassifier {
  static const _kMaxDistanceTopK = 30;
  static const _kMeanDistanceTopK = 10;

  //注意⚠️ Z 的权重较低，因为它通常不如 X 和 Y 准确。
  static final PointF3D _kAxesWeights = PointF3D.from(1, 1, 0.2);

  final List<PoseSample> poseSamples;
  final int maxDistanceTopK;
  final int meanDistanceTopK;
  final PointF3D axesWeights;

  PoseClassifier({required this.poseSamples})
      : maxDistanceTopK = _kMaxDistanceTopK,
        meanDistanceTopK = _kMeanDistanceTopK,
        axesWeights = _kAxesWeights;

  ///ios返回的[pose.landmarks]与Android返回的顺序不一致导致ios不能计数
  ///这里将[pose.landmarks]转为按[PoseLandmarkType]按[index]从小到大排序完之后再转换为[PointF3D]的列表
  static List<PointF3D> _extractPoseLandmarks(Pose pose, Size inputImageSize) {
    final SplayTreeMap<PoseLandmarkType, PoseLandmark> st = SplayTreeMap.from(pose.landmarks, (a, b) => a.index.compareTo(b.index));
    List<PointF3D> landmarks = [];
    for (PoseLandmark poseLandmark in st.values) {
      landmarks.add(PointF3D.from(poseLandmark.x, poseLandmark.y, poseLandmark.z));
    }
    return landmarks;
  }

  /// Returns the max range of confidence values.
  ///
  /// <p><Since we calculate confidence by counting [PoseSample]s that survived
  /// outlier-filtering by [maxDistanceTopK] and [meanDistanceTopK], this range is the minimum of two.
  int confidenceRange() {
    return min(maxDistanceTopK, meanDistanceTopK);
  }

  ClassificationResult classify(Pose pose, Size inputImageSize) {
    return getClassify(_extractPoseLandmarks(pose, inputImageSize));
  }

  ClassificationResult getClassify(List<PointF3D> landmarks) {
    ClassificationResult result = ClassificationResult();
    // Return early if no landmarks detected.
    if (landmarks.isEmpty) {
      return result;
    }

    // We do flipping on X-axis so we are horizontal (mirror) invariant.
    List<PointF3D> flippedLandmarks = multiplyAllP(landmarks, PointF3D.from(-1, 1, 1));
    List<PointF3D> embedding = PoseEmbedding.getPoseEmbedding(landmarks);
    List<PointF3D> flippedEmbedding = PoseEmbedding.getPoseEmbedding(flippedLandmarks);

    // Classification is done in two stages:
    //  * First we pick top-K samples by MAX distance. It allows to remove samples that are almost
    //    the same as given pose, but maybe has few joints bent in the other direction.
    //  * Then we pick top-K samples by MEAN distance. After outliers are removed, we pick samples
    //    that are closest by average.

    // Keeps max distance on top so we can pop it when top_k size is reached.
    PriorityQueue<PoseSamplePair> maxDistances = MyPriorityQueue(_kMaxDistanceTopK, (a, b) => -(a.minValue.compareTo(b.minValue)));
    // Retrieve top K poseSamples by least distance to remove outliers.
    for (PoseSample poseSample in poseSamples) {
      List<PointF3D> sampleEmbedding = poseSample.getEmbedding();
      double originalMax = 0;
      double flippedMax = 0;
      for (int i = 0; i < embedding.length; i++) {
        originalMax = max(originalMax, maxAbs(multiplyP(subtract(embedding[i], sampleEmbedding[i]), axesWeights)));
        flippedMax = max(flippedMax, maxAbs(multiplyP(subtract(flippedEmbedding[i], sampleEmbedding[i]), axesWeights)));
      }
      // Set the max distance as min of original and flipped max distance.
      maxDistances.add(PoseSamplePair(poseSample, min(originalMax, flippedMax)));
      // We only want to retain top n so pop the highest distance.
      if (maxDistances.length > maxDistanceTopK) {
        maxDistances.removeFirst();
      }
    }
    // Keeps higher mean distances on top so we can pop it when top_k size is reached.
    PriorityQueue<PoseSamplePair> meanDistances = MyPriorityQueue(_kMeanDistanceTopK, (a, b) => -(a.minValue.compareTo(b.minValue)));
    // Retrive top K poseSamples by least mean distance to remove outliers.
    for (PoseSamplePair sampleDistances in maxDistances.unorderedElements) {
      PoseSample poseSample = sampleDistances.poseSample;
      List<PointF3D> sampleEmbedding = poseSample.getEmbedding();
      double originalSum = 0;
      double flippedSum = 0;
      for (int i = 0; i < embedding.length; i++) {
        originalSum += sumAbs(multiplyP(subtract(embedding[i], sampleEmbedding[i]), axesWeights));
        flippedSum += sumAbs(multiplyP(subtract(flippedEmbedding[i], sampleEmbedding[i]), axesWeights));
      }

      // Set the mean distance as min of original and flipped mean distances.
      double meanDistance = min(originalSum, flippedSum) / (embedding.length * 2);
      // print(meanDistance);
      meanDistances.add(PoseSamplePair(poseSample, meanDistance));
      // We only want to retain top k so pop the highest mean distance.
      if (meanDistances.length > meanDistanceTopK) {
        meanDistances.removeFirst();
      }
    }
    for (PoseSamplePair sampleDistances in meanDistances.unorderedElements) {
      String className = sampleDistances.poseSample.getClassName();
      result.incrementClassConfidence(className);
    }
    return result;
  }
}

class PoseSamplePair {
  PoseSamplePair(
    this.poseSample,
    this.minValue,
  );

  final double minValue;
  final PoseSample poseSample;

  @override
  String toString() {
    return 'PoseSamplePair('
        'poseSample:$poseSample,'
        'minValue:$minValue)';
  }
}
