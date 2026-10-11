// 悬浮窗控制：权限申请、显隐、把开局识别结果灌给悬浮窗
//
// 关键设计：悬浮窗运行在独立的 Flutter 引擎里，无法直接访问主 App 的全局状态。
// 因此开局识别结果先写入 shared_preferences，悬浮窗启动时再读出来作为初始已见牌。
import 'dart:convert';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';

const _kDecks = 'ov_decks';
const _kHand = 'ov_hand';
const _kSeen = 'ov_seen';

// 检查/申请"在其他应用上层显示"权限
Future<bool> ensureOverlayPermission() async {
  if (await FlutterOverlayWindow.isPermissionGranted()) return true;
  return FlutterOverlayWindow.requestPermission();
}

// 把当前主 App 的对局状态（已见牌）写入共享存储，供悬浮窗启动时读取
Future<void> seedOverlayFromGameState() async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(_kDecks, gameState.decks);
  await p.setInt(_kHand, 0);
  final map = <String, int>{};
  for (final t in gameState.types) {
    map[t.key] = gameState.seenByType[t.key] ?? 0;
  }
  await p.setString(_kSeen, jsonEncode(map));
}

// 启动悬浮窗：先（可选）写入开局识别结果，再拉起悬浮窗（盖在游戏/桌面上方）
Future<void> showCounterOverlay({bool seed = false}) async {
  final granted = await ensureOverlayPermission();
  if (!granted) return;
  if (seed) await seedOverlayFromGameState();
  await FlutterOverlayWindow.showOverlay(
    alignment: OverlayAlignment.topCenter,
    enableDrag: true,
    width: 360,
    height: 560,
  );
}

// 关闭悬浮窗
Future<void> hideCounterOverlay() async {
  await FlutterOverlayWindow.closeOverlay();
}

// 主 App 实时把计数推给已开启的悬浮窗（开局识别后即时刷新用）
Future<void> pushSummaryToOverlay() async {
  final g = gameState;
  final map = {
    'lastScreen': g.lastScreenCount,
    'seen': g.seenCards(),
    'total': g.totalCards(),
    'remain': g.remainingCards(),
    'r5': g.remainingOfRank(5),
    'r10': g.remainingOfRank(10),
    'rK': g.remainingOfRank(13),
  };
  try {
    await FlutterOverlayWindow.shareData(jsonEncode(map));
  } catch (_) {
    // 悬浮窗未开启时忽略
  }
}
