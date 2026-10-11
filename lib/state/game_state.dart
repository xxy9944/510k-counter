// 对局状态与计数核心逻辑
//
// 思路（记牌器通用算法）：
//   总牌数 = 54 种 × 副数（4人3副 = 162 张）
//   已见牌 = 历次截屏识别结果的"并集"（出过的牌始终算已见，只增不减）
//   对手合计剩余 = 总牌数 − 已见牌
//   关键牌(5/10/K)剩余 = 该点数总张数 − 已见张数
import '../models/card_model.dart';
import '../models/deck.dart';

class GameState {
  final int decks; // 副数，510k 常用 3
  late List<CardType> types;
  late Map<String, int> totalByType; // 每种牌总张数 = decks
  Map<String, int> seenByType = {}; // 本局累计已识别到的张数（取并集/最大值）
  int lastScreenCount = 0; // 最近一次截屏识别到的张数（"本屏识别"）

  GameState({this.decks = 3}) {
    types = buildDeckTypes();
    totalByType = {for (final t in types) t.key: decks};
    for (final t in types) seenByType[t.key] = 0;
  }

  // 合并一次截屏识别结果（detected: 牌key -> 本次识别张数）
  // 用并集逻辑：已见只增不减
  void mergeDetection(Map<String, int> detected) {
    for (final t in types) {
      final d = detected[t.key] ?? 0;
      if (d > seenByType[t.key]!) seenByType[t.key] = d;
    }
    lastScreenCount = detected.values.fold(0, (a, b) => a + b);
  }

  int totalCards() => types.fold(0, (s, t) => s + totalByType[t.key]!);
  int seenCards() => seenByType.values.fold(0, (a, b) => a + b);
  int remainingCards() => totalCards() - seenCards();

  // 某点数还剩几张（用于 5/10/K 关键牌）
  int remainingOfRank(int rank) {
    int total = 0, seen = 0;
    for (final t in types) {
      if (t.rank == rank) {
        total += totalByType[t.key]!;
        seen += seenByType[t.key]!;
      }
    }
    return total - seen;
  }

  int remainingScoreCards() =>
      remainingOfRank(5) + remainingOfRank(10) + remainingOfRank(13);

  // 新开一局时清空
  void reset() {
    for (final t in types) seenByType[t.key] = 0;
    lastScreenCount = 0;
  }
}
