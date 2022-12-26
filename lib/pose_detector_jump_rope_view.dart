import 'dart:async';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_detect_poses/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'camera_view.dart';
import 'posederector/classification/pose_classifier_processor.dart';

class PoseDetectorJumpRopeView extends StatefulWidget {
  const PoseDetectorJumpRopeView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PoseDetectorJumpRopeViewState();
}

class _PoseDetectorJumpRopeViewState extends State<PoseDetectorJumpRopeView> {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  bool _showCounter = false;
  String _counterResult = '';

  //y坐标数组
  List<double> _centerYList = [];

  List<int> centerYs = [];
  List<int> handCenterYs = [];
  List<int> handCenterYDifferences = [];

  double _count = 0;
  bool _flag = false;

  PoseClassifierProcessor? poseClassifierProcessor;

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    if (mounted) poseClassifierProcessor = null;
    super.dispose();
  }

  @override
  initState() {
    poseClassifierProcessor = PoseClassifierProcessor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          CameraView(
            customPaint: _customPaint,
            text: _text,
            onImage: (inputImage) {
              processJumpRopeImage(inputImage);
              // processJumpRopeImage(inputImage);
            },
          ),
          _showCounter
              ? CountView(
                  count: _count,
                  stopCounter: () async {
                    await _poseDetector.close();
                    setState(() {
                      _canProcess = false;
                      _customPaint = null;
                    });
                    print('停止计数');
                  },
                )
              : const SizedBox(),
          // Positioned(
          //   left: 20,
          //   bottom: 100,
          //   child: Text(
          //     _counterResult,
          //     style: const TextStyle(fontSize: 30, color: Colors.white),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    List<Pose> poses = await _poseDetector.processImage(inputImage);
    List<String> result = [];
    if (poses.isNotEmpty && mounted) {
      result = poseClassifierProcessor!.getPoseResult(poses.first, inputImage.inputImageData!.size);
      _counterResult = '${result.first}\n${result.last}';
      LogUtil.e(_counterResult);
    }
    if (inputImage.inputImageData?.size != null && inputImage.inputImageData?.imageRotation != null) {
      // LogUtil.e(inputImage.inputImageData?.imageRotation);
      final painter = PosePainter(
        poses,
        inputImage.inputImageData!.size,
        inputImage.inputImageData!.imageRotation,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Poses found: ${poses.length}\n\n';
      // TODO: set _customPaint to draw landmarks on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> processJumpRopeImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isNotEmpty) {
      bool isFullMen = poses.first.landmarks.values.every((element) {
        if (Platform.isIOS) {
          return element.x < inputImage.inputImageData!.size.width && element.y < inputImage.inputImageData!.size.height;
        } else {
          return element.x < inputImage.inputImageData!.size.height && element.y < inputImage.inputImageData!.size.width;
        }
      });
      if (isFullMen && mounted) {
        setState(() {
          _showCounter = true;
        });
        PoseLandmark leftHip = poses.first.landmarks[PoseLandmarkType.leftHip]!;
        PoseLandmark rightHip = poses.first.landmarks[PoseLandmarkType.rightHip]!;
        double centerY = (leftHip.y + rightHip.y) / 2;
        double centerX = (leftHip.x + rightHip.x) / 2;
        //计算鼻子到脚尖的距离
        PoseLandmark nose = poses.first.landmarks[PoseLandmarkType.nose]!;
        PoseLandmark rightFootIndex = poses.first.landmarks[PoseLandmarkType.rightFootIndex]!;
        PoseLandmark leftFootIndex = poses.first.landmarks[PoseLandmarkType.leftFootIndex]!;
        final double footIndexCenterY = (rightFootIndex.y + leftFootIndex.y) / 2;
        final double noseHeight = footIndexCenterY - nose.y;
        // final double handCenterY = (poses.first.landmarks[PoseLandmarkType.leftWrist]!.y + poses.first.landmarks[PoseLandmarkType.rightWrist]!.y) / 2;
        // _getPlotData(centerY, handCenterY);
        _getCount(centerY, noseHeight);
        if (inputImage.inputImageData?.size != null && inputImage.inputImageData?.imageRotation != null) {
          final painter = PosePainter(poses, inputImage.inputImageData!.size, inputImage.inputImageData!.imageRotation, centerX: centerX, centerY: centerY);
          _customPaint = CustomPaint(painter: painter);
        } else {
          _text = 'Poses found: ${poses.length}\n\n';
          // TODO: set _customPaint to draw landmarks on top of image
          _customPaint = null;
        }
      }
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _getPlotData(double centerY, double handCenterY) {
    centerYs.add(centerY.toInt());
    handCenterYs.add((handCenterY - centerY).toInt());
    handCenterYDifferences.add((handCenterY).toInt());
    // LogUtil.d(123);
    LogUtil.e(centerYs);
    LogUtil.e(handCenterYs);
    LogUtil.e(handCenterYDifferences);
  }

  void _getCount(double y, double noseHeight) {
    _centerYList.add(y);
    if (_centerYList.length < 2) return;
    double prevFlip = _centerYList[_centerYList.length - 2];
    if (y < prevFlip - noseHeight * 0.01 && _flag == false) {
      _flag = true;
    } else if (y > prevFlip + noseHeight * 0.01 && _flag == true) {
      setState(() {
        _count++;
      });
      _flag = false;
    }
  }
}

class CountView extends StatefulWidget {
  const CountView({
    Key? key,
    required double count,
    required this.stopCounter,
  })  : _count = count,
        super(key: key);

  final double _count;
  final VoidCallback stopCounter;

  @override
  State<CountView> createState() => _CountViewState();
}

class _CountViewState extends State<CountView> {
  int times = 60;
  int readyTime = 3;

  @override
  initState() {
    _ready3s();
    super.initState();
  }

  _ready3s() {
    Duration duration = const Duration(seconds: 1);
    Timer.periodic(duration, (timer) {
      if (mounted) {
        setState(() {
          readyTime--;
        });
      }
      if (readyTime <= 0) {
        timer.cancel();
        _startTimer();
      }
    });
  }

  _startTimer() {
    Duration duration = const Duration(seconds: 1);
    Timer.periodic(duration, (timer) {
      if (mounted) {
        setState(() {
          times--;
        });
      }
      if (times <= 0) {
        timer.cancel();
        widget.stopCounter.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        top: 50,
        left: 8,
        child: Stack(
          children: [
            readyTime > 0
                ? const SizedBox()
                : DefaultTextStyle(
                    style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 24, fontWeight: FontWeight.w600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        //倒计时
                        Text('时间00:${times >= 10 ? times : '0$times'}'),
                        Text(
                          '跳绳次数：${widget._count.ceil()}',
                        ),
                      ],
                    ),
                  ),
            readyTime > 0
                ? Center(
                    child: Text(
                      '$readyTime',
                      style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 80, fontWeight: FontWeight.w600),
                    ),
                  )
                : const SizedBox(),
          ],
        ));
  }
}
