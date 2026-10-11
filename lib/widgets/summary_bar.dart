// 悬浮栏（对局信息条）：实时显示牌局情况
// 放在每个页面的顶部，随每次新截图刷新。
import 'package:flutter/material.dart';
import '../globals.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key});

  @override
  Widget build(BuildContext c) {
    final g = gameState;
    return Container(
      color: Colors.teal.shade50,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本屏识别：${g.lastScreenCount} 张',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('累计已见：${g.seenCards()} / ${g.totalCards()} 张'),
          Text('对手合计剩余：${g.remainingCards()} 张',
              style: const TextStyle(fontSize: 16, color: Colors.red)),
          Text(
              '关键牌剩余 → 5剩${g.remainingOfRank(5)} · 10剩${g.remainingOfRank(10)} · K剩${g.remainingOfRank(13)}'),
        ],
      ),
    );
  }
}
