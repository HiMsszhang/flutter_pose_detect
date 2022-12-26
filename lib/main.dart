import 'package:camera/camera.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_detect_poses/pose_detector_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pose_detector_jump_rope_view.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  LogUtil.init(maxLen: 1000);
  SystemChrome.setPreferredOrientations([
    // 强制竖屏
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('zh'),
      supportedLocales: const [
        Locale('en'), // 美国英语
        Locale('zh'), // 中文简体
      ],
      routes: {
        '/poseDetectorView': (context) => const PoseDetectorView(),
        '/poseDetectorJumpRopeView': (context) => const PoseDetectorJumpRopeView(),
      },
      // onGenerateInitialRoutes: ,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: "AI运动测试",
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/poseDetectorJumpRopeView', arguments: '跳绳计数');
                },
                child: Text('跳绳计数')),
            TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/poseDetectorView', arguments: '动作计数');
                },
                child: Text('动作计数')),
          ],
        ),
      ),
    );
  }
}

class MyDataTable extends StatelessWidget {
  const MyDataTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(
          color: Color(0xFFD8D8D8),
          width: 1,
          style: BorderStyle.solid,
          borderRadius: BorderRadius.circular(1),
        ),
        columnWidths: {
          1: FixedColumnWidth(MediaQuery.of(context).size.width * .25),
          2: FixedColumnWidth(MediaQuery.of(context).size.width * .25),
          3: FixedColumnWidth(MediaQuery.of(context).size.width * .25),
          4: FixedColumnWidth(MediaQuery.of(context).size.width * .25),
        },
        children: [
          TableRow(
              decoration: BoxDecoration(
                color: Color(0xFFB1DDDD),
              ),
              children: [
                //增加行高
                buildSizedBox(text: '随访日期'),
                buildSizedBox(text: '2022-03-01'),
                buildSizedBox(text: '2022-03-01'),
                buildSizedBox(text: '-'),
              ]),
          buildTableRow(children: [
            buildSizedBox(text: '随访日期'),
            buildSizedBox(text: '等回家看是打卡机撒谎的卡号丹砂博大精深吧大叔丢啊实打实都iu撒谎都啊啥都啊山东i阿萨德后i撒多喝水减肥黑科技啊舒服啦沙发舒服了舒服凉快舒服好的挥洒多喝水都洒活动经典款垃圾袋里卡时间点进啊是巨大'),
            buildSizedBox(text: '随访日期'),
            buildSizedBox(text: '随访日期'),
          ]),
        ],
      ),
    );
  }

  TableRow buildTableRow({
    required List<Widget>? children,
  }) {
    return TableRow(children: children);
  }

  AutoHeight buildSizedBox({
    required String text,
    TextStyle? style,
  }) {
    return AutoHeight(
      text: text,
    );
  }
}

class AutoHeight extends StatefulWidget {
  const AutoHeight({
    Key? key,
    this.style,
    required this.text,
  }) : super(key: key);
  final TextStyle? style;
  final String text;

  @override
  State<AutoHeight> createState() => _AutoHeightState();
}

class _AutoHeightState extends State<AutoHeight> {
  GlobalKey key = GlobalKey();
  double height = 0;
  late Size textSize;

  Size boundingTextSize(String text, TextStyle style, {int maxLines = 2 ^ 31, double maxWidth = double.infinity}) {
    if (text == null || text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr, text: TextSpan(text: text, style: style), maxLines: maxLines)..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    textSize = boundingTextSize(widget.text, const TextStyle(fontWeight: FontWeight.bold));
    final h = (textSize.width / (MediaQuery.of(context).size.width * 0.25 * .9)).ceil() * textSize.height;
    print((textSize.width / (MediaQuery.of(context).size.width * 0.25)).ceil() * textSize.height);
    return SizedBox(
      height: h <= 40 ? 40 : h,
      child: Center(
        child: OverflowBox(
          child: Text(
            key: key,
            widget.text,
            style: widget.style ?? const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
