import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'point_3d.dart';
import 'utils.dart';

class PoseEmbedding {
  // Multiplier to apply to the torso to get minimal body size. Picked this by experimentation.
  static const double _kTorsoMultiplier = 2.5;

  static List<PointF3D> getPoseEmbedding(List<PointF3D> landmarks) {
    List<PointF3D> normalizedLandmarks = normalize(landmarks);
    return getEmbedding(normalizedLandmarks);
  }

  static List<PointF3D> normalize(List<PointF3D> landmarks) {
    List<PointF3D> normalizedLandmarks = landmarks;
    // Normalize translation.
    PointF3D center = average(landmarks[PoseLandmarkType.leftHip.index], landmarks[PoseLandmarkType.rightHip.index]);
    normalizedLandmarks = subtractAll(center, normalizedLandmarks);

    // Normalize scale.
    normalizedLandmarks = multiplyAll(normalizedLandmarks, 1 / getPoseSize(normalizedLandmarks));
    // Multiplication by 100 is not required, but makes it easier to debug.
    normalizedLandmarks = multiplyAll(normalizedLandmarks, 100);
    return normalizedLandmarks;
  }

  // Translation normalization should've been done prior to calling this method.
  static double getPoseSize(List<PointF3D> landmarks) {
    // Note: This approach uses only 2D landmarks to compute pose size as using Z wasn't helpful
    // in our experimentation but you're welcome to tweak.
    PointF3D hipsCenter = average(landmarks[PoseLandmarkType.leftHip.index], landmarks[PoseLandmarkType.rightHip.index]);

    PointF3D shouldersCenter = average(landmarks[PoseLandmarkType.leftShoulder.index], landmarks[PoseLandmarkType.rightShoulder.index]);

    double torsoSize = l2Norm2D(subtract(hipsCenter, shouldersCenter));

    double maxDistance = torsoSize * _kTorsoMultiplier;
    // torsoSize * TORSO_MULTIPLIER is the floor we want based on experimentation but actual size
    // can be bigger for a given pose depending on extension of limbs etc so we calculate that.
    for (PointF3D landmark in landmarks) {
      double distance = l2Norm2D(subtract(hipsCenter, landmark));
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
    return maxDistance;
  }

  static List<PointF3D> getEmbedding(List<PointF3D> lm) {
    List<PointF3D> embedding = [];

    // We use several pairwise 3D distances to form pose embedding. These were selected
    // based on experimentation for best results with our default pose classes as captued in the
    // pose samples csv. Feel free to play with this and add or remove for your use-cases.

    // We group our distances by number of joints between the pairs.
    // One joint.
    embedding.add(subtract(
      average(
        lm[PoseLandmarkType.leftHip.index],
        lm[PoseLandmarkType.rightHip.index],
      ),
      average(
        lm[PoseLandmarkType.leftShoulder.index],
        lm[PoseLandmarkType.rightShoulder.index],
      ),
    ));
    embedding.add(subtract(lm[PoseLandmarkType.leftShoulder.index], lm[PoseLandmarkType.leftElbow.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightShoulder.index], lm[PoseLandmarkType.rightElbow.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftElbow.index], lm[PoseLandmarkType.leftWrist.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightElbow.index], lm[PoseLandmarkType.rightWrist.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftHip.index], lm[PoseLandmarkType.leftKnee.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightHip.index], lm[PoseLandmarkType.rightKnee.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftKnee.index], lm[PoseLandmarkType.leftAnkle.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightKnee.index], lm[PoseLandmarkType.rightAnkle.index]));

    // Two joints.
    embedding.add(subtract(lm[PoseLandmarkType.leftShoulder.index], lm[PoseLandmarkType.leftWrist.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightShoulder.index], lm[PoseLandmarkType.rightWrist.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftHip.index], lm[PoseLandmarkType.leftAnkle.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightHip.index], lm[PoseLandmarkType.rightAnkle.index]));

    // Four joints.
    embedding.add(subtract(lm[PoseLandmarkType.leftHip.index], lm[PoseLandmarkType.leftWrist.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightHip.index], lm[PoseLandmarkType.rightWrist.index]));

    // Five joints.
    embedding.add(subtract(lm[PoseLandmarkType.leftShoulder.index], lm[PoseLandmarkType.leftAnkle.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightShoulder.index], lm[PoseLandmarkType.rightAnkle.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftHip.index], lm[PoseLandmarkType.leftWrist.index]));
    embedding.add(subtract(lm[PoseLandmarkType.rightHip.index], lm[PoseLandmarkType.rightWrist.index]));

    // Cross body.
    embedding.add(subtract(lm[PoseLandmarkType.leftElbow.index], lm[PoseLandmarkType.rightElbow.index]));
    embedding.add(subtract(lm[PoseLandmarkType.leftKnee.index], lm[PoseLandmarkType.rightKnee.index]));

    embedding.add(subtract(lm[PoseLandmarkType.leftWrist.index], lm[PoseLandmarkType.rightWrist.index]));
    embedding.add(subtract(lm[PoseLandmarkType.leftAnkle.index], lm[PoseLandmarkType.rightAnkle.index]));

    return embedding;
  }
}
