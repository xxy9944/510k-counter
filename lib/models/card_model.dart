// 牌的数据模型
// 一副标准扑克牌有 54 种：13 个点数 × 4 种花色 + 大小王
// 510k 里 5、10、K 是关键计分牌，所以单独标出来。

enum Suit { spade, heart, club, diamond, joker }

class CardType {
  final Suit suit;
  // 点数编码：3..10 原值；11=J 12=Q 13=K 14=A 15=2；16=小王 17=大王
  final int rank;
  final String label;

  CardType(this.suit, this.rank, this.label);

  // 同一张牌的稳定标识，用作模板/计数的 key
  String get key => '$suit-$rank';

  // 510k 计分牌：5、10、K 各 10 分
  bool get isScoreCard => rank == 5 || rank == 10 || rank == 13;
}

// 点数 -> 中文/符号名
String rankName(int r) {
  const map = {11: 'J', 12: 'Q', 13: 'K', 14: 'A', 15: '2'};
  if (r >= 3 && r <= 10) return '$r';
  if (r == 16) return '小王';
  if (r == 17) return '大王';
  return map[r] ?? '$r';
}

String suitName(Suit s) {
  switch (s) {
    case Suit.spade:
      return '♠';
    case Suit.heart:
      return '♥';
    case Suit.club:
      return '♣';
    case Suit.diamond:
      return '♦';
    case Suit.joker:
      return '王';
  }
}
