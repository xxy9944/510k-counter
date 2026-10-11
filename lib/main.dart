import 'package:flutter/material.dart';
import 'globals.dart';
import 'screens/home_screen.dart';
import 'overlay/overlay_entry.dart'; // 悬浮窗入口 overlayMain（必须被编译进 App）

// 入口：初始化模板库，启动主界面。
// 开局截图通过首页「导入一张对局截图」按钮（ImagePicker）进入识别页，
// 不再依赖 receive_sharing_intent，避免其 Gradle 编译冲突。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await templateStore.init();
  runApp(const MyApp());
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
