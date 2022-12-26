# flutter_detect_poses

基于mediaPipe实现的AI运动计数事例
## Getting Started
相关代码从MLkit事例Android开源代码迁移至flutter
关键代码目录：lib/posederector/classification
调用：
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
