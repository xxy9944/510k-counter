// 首页：配置与入口
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../globals.dart';
import 'template_screen.dart';
import 'result_screen.dart';
import '../services/overlay_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int filled = 0;
  bool _overlayOn = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => filled = templateStore.filledCount);

  Future<void> _toggleOverlay() async {
    if (_overlayOn) {
      await hideCounterOverlay();
      setState(() => _overlayOn = false);
    } else {
      // 把当前对局（含开局识别结果）写入共享存储，再拉起悬浮窗
      await showCounterOverlay(seed: true);
      setState(() => _overlayOn = true);
    }
  }

  Future<void> _pick() async {
    final img =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => ResultScreen(imagePath: img.path)));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('510k 自动记牌器')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('玩法：四人三副牌（162 张）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('牌样模板已录入：$filled / 54',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              if (!templateStore.isComplete)
                const Text('⚠️ 识别前请先录入全部 54 种牌的样图',
                    style: TextStyle(color: Colors.orange)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TemplateScreen()))
                      .then((_) => _refresh()),
                  icon: const Icon(Icons.grid_view),
                  label: const Text('管理牌样（模板）')),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                  onPressed: templateStore.isComplete ? _pick : null,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('导入一张对局截图')),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                  onPressed: _toggleOverlay,
                  icon: const Icon(Icons.picture_in_picture),
                  label: Text(_overlayOn ? '关闭悬浮窗' : '启动对战悬浮窗（浮在游戏上）')),
              const SizedBox(height: 12),
              const Text(
                  '使用步骤：① 先在「管理牌样」录入 54 种牌样图；② 开局截一张整屏 → 「导入截图」自动识别你的手牌；③ 点「启动对战悬浮窗」→ 之后直接在悬浮窗里点牌记录打出的牌，不用来回切 App。',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
