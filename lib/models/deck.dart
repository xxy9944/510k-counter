// 生成一副牌的 54 种类型（不重复，计数由"副数"决定）
import 'card_model.dart';

List<CardType> buildDeckTypes() {
  const suits = [Suit.spade, Suit.heart, Suit.club, Suit.diamond];
  final List<CardType> types = [];
  for (final s in suits) {
    for (int r = 3; r <= 15; r++) {
      types.add(CardType(s, r, '${suitName(s)}${rankName(r)}'));
    }
  }
  types.add(CardType(Suit.joker, 16, '小王'));
  types.add(CardType(Suit.joker, 17, '大王'));
  return types;
}
