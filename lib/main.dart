import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'globals.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'overlay/overlay_entry.dart'; // 悬浮窗入口 overlayMain（必须被编译进 App）

// 入口：初始化模板库，监听"从系统分享进来的截图"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await templateStore.init();

  runApp(const MyApp());

  // 冷启动时如果带了分享的截图
  ReceiveSharingIntent.instance.getInitialMedia().then((files) {
    if (files.isNotEmpty) _openScreenshot(files.first.path);
  });
  // App 已在后台时，收到分享
  ReceiveSharingIntent.instance.getMediaStream().listen((files) {
    if (files.isNotEmpty) _openScreenshot(files.first.path);
  }, onError: (e) {/* 忽略 */});
}

// 拿到一张分享/选中的截图，就跳到识别页
void _openScreenshot(String path) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => ResultScreen(imagePath: path)),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        navigatorKey: navigatorKey,
        title: '510k 自动记牌器',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const HomeScreen(),
      );
}
