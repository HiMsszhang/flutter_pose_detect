import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'coordinates_translator.dart';

class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.absoluteImageSize, this.rotation, {this.centerX, this.centerY});

  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final double? centerX;
  final double? centerY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.deepPurpleAccent;

    final paintCenter = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..color = Colors.redAccent;

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.redAccent;
    void paintText(Offset offset, double value) {
      var textPainter = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 8)),
        textDirection: TextDirection.rtl,
        textWidthBasis: TextWidthBasis.longestLine,
        maxLines: 1,
      )..layout();
      textPainter.paint(canvas, offset);
    }

    if (centerY != null) {
      canvas.drawCircle(
          Offset(
            translateX(centerX!, rotation, size, absoluteImageSize),
            translateY(centerY!, rotation, size, absoluteImageSize),
          ),
          5,
          paintCenter);

      paintText(
        Offset(
          translateX(centerX!, rotation, size, absoluteImageSize),
          translateY(centerY!, rotation, size, absoluteImageSize),
        ),
        centerY!,
      );
    }

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            1,
            paint);
        paintText(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            landmark.likelihood);
      });

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
          Offset(translateX(joint1.x, rotation, size, absoluteImageSize), translateY(joint1.y, rotation, size, absoluteImageSize)),
          Offset(translateX(joint2.x, rotation, size, absoluteImageSize), translateY(joint2.y, rotation, size, absoluteImageSize)),
          paintType,
        );
      }

      //Draw face
      paintLine(PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth, bodyPaint);
      paintLine(PoseLandmarkType.rightEyeInner, PoseLandmarkType.nose, bodyPaint);
      paintLine(PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye, bodyPaint);
      paintLine(PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter, bodyPaint);
      paintLine(PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar, bodyPaint);
      paintLine(PoseLandmarkType.leftEyeInner, PoseLandmarkType.nose, bodyPaint);
      paintLine(PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye, bodyPaint);
      paintLine(PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter, bodyPaint);
      paintLine(PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar, bodyPaint);

      //Draw leftShoulder to rightShoulder
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, bodyPaint);

      //Draw arms
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, bodyPaint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, bodyPaint);
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky, bodyPaint);
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb, bodyPaint);
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex, bodyPaint);
      paintLine(PoseLandmarkType.leftPinky, PoseLandmarkType.leftIndex, bodyPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, bodyPaint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, bodyPaint);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky, bodyPaint);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb, bodyPaint);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex, bodyPaint);
      paintLine(PoseLandmarkType.rightPinky, PoseLandmarkType.rightIndex, bodyPaint);

      //Draw Body
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, bodyPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, bodyPaint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, bodyPaint);

      //Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, bodyPaint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, bodyPaint);
      paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel, bodyPaint);
      paintLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex, bodyPaint);
      paintLine(PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex, bodyPaint);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, bodyPaint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, bodyPaint);
      paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel, bodyPaint);
      paintLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex, bodyPaint);
      paintLine(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize || oldDelegate.poses != poses;
  }
}
