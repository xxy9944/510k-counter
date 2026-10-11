// 识别结果页：拿到截图 -> 识别 -> 合并计数 -> 显示悬浮栏 + 命中明细
import 'dart:io';
import 'package:flutter/material.dart';
import '../globals.dart';
import '../services/recognizer.dart';
import '../services/overlay_service.dart';
import 'package:flutter/services.dart';
import '../models/deck.dart';
import '../widgets/summary_bar.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  const ResultScreen({super.key, required this.imagePath});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool loading = false;
  Map<String, int> detected = {};
  String error = '';

  Future<void> _run() async {
    setState(() => loading = true);
    try {
      final r = await recognize(File(widget.imagePath), templateStore);
      gameState.mergeDetection(r);
      pushSummaryToOverlay(); // 推到悬浮窗（若已开启）
      setState(() => detected = r);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('对局识别')),
        body: Column(children: [
          const SummaryBar(),
          if (loading) const LinearProgressIndicator(),
          if (error.isNotEmpty)
            Text('识别出错：$error', style: const TextStyle(color: Colors.red)),
          Expanded(child: Image.file(File(widget.imagePath))),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 6,
              children: detected.entries.map((e) {
                final t = buildDeckTypes()
                    .firstWhere((x) => x.key == e.key);
                return Chip(label: Text('${t.label} ×${e.value}'));
              }).toList(),
            ),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('再截一张（返回首页继续）')),
          const SizedBox(height: 8),
          ElevatedButton.icon(
              onPressed: () async {
                await showCounterOverlay(seed: true); // 写入开局识别结果并拉起悬浮窗
                SystemNavigator.pop(); // 把 App 退到后台，只留悬浮窗 + 游戏画面
              },
              icon: const Icon(Icons.visibility),
              label: const Text('启动对战悬浮窗（返回游戏）')),
        ]),
      );
}
