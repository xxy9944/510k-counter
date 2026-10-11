// 系统悬浮窗入口与 UI（可操作版）
//
// 这是盖在微信小程序 / 桌面之上的"真·悬浮窗"。它运行在独立的 Flutter 引擎里，
// 自己持有对局状态：显示剩余张数 + 关键牌(5/10/K)剩余，并支持直接点牌录入"打出的牌"。
// 开局识别结果由主 App 写入 shared_preferences，这里启动时读出来作为初始已见牌。
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/deck.dart';

const _kDecks = 'ov_decks';
const _kHand = 'ov_hand';
const _kSeen = 'ov_seen';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});
  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  final List<CardType> _types = buildDeckTypes();
  int _decks = 3;
  Map<String, int> _seen = {};
  final List<String> _undo = [];
  int _myHand = 0;
  bool _input = false;
  bool _loading = true;
  Suit _activeSuit = Suit.spade;

  @override
  void initState() {
    super.initState();
    _load();
    // 主 App 通过 shareData 推来的"增量加牌"也接住
    FlutterOverlayWindow.overlayListener.listen((e) {
      try {
        final m = jsonDecode(e) as Map<String, dynamic>;
        if (m['cmd'] == 'add' && m['key'] is String) {
          _add(_types.firstWhere((t) => t.key == m['key']));
        }
      } catch (_) {}
    });
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _decks = p.getInt(_kDecks) ?? 3;
    _myHand = p.getInt(_kHand) ?? 0;
    final s = p.getString(_kSeen);
    if (s != null) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      _seen = m.map((k, v) => MapEntry(k, v as int));
    }
    for (final t in _types) _seen.putIfAbsent(t.key, () => 0);
    setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDecks, _decks);
    await p.setInt(_kHand, _myHand);
    await p.setString(_kSeen, jsonEncode(_seen));
  }

  void _add(CardType t) {
    setState(() {
      _seen[t.key] = (_seen[t.key] ?? 0) + 1;
      _undo.add(t.key);
    });
    _persist();
  }

  void _undoOne() {
    if (_undo.isEmpty) return;
    final k = _undo.removeLast();
    setState(() => _seen[k] = (_seen[k] ?? 1) - 1);
    _persist();
  }

  Future<void> _reset() async {
    setState(() {
      for (final t in _types) _seen[t.key] = 0;
      _undo.clear();
      _myHand = 0;
      _input = false;
    });
    await _persist();
  }

  int get _total => _types.length * _decks;
  int get _seenCount => _seen.values.fold(0, (a, b) => a + b);
  int get _remainUnknown => _total - _seenCount;
  int get _oppRemain => (_remainUnknown - _myHand).clamp(0, _total);

  int _remainOfRank(int rank) {
    int tot = 0, seen = 0;
    for (final t in _types) {
      if (t.rank == rank) {
        tot += _decks;
        seen += _seen[t.key] ?? 0;
      }
    }
    return tot - seen;
  }

  Color _suitColor(Suit s) {
    if (s == Suit.heart || s == Suit.diamond) return Colors.red;
    if (s == Suit.joker) return Colors.grey;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Colors.transparent),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.topCenter,
          child: _input ? _buildInputCard() : _buildSummaryCard(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() => Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.shade800.withOpacity(0.94),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('510k 记牌',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => FlutterOverlayWindow.closeOverlay(),
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ]),
            const SizedBox(height: 6),
            Text('已出 $_seenCount / 共 $_total    剩余未知 $_remainUnknown',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            Text('对手合计剩 $_oppRemain 张',
                style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('5剩 ${_remainOfRank(5)}   10剩 ${_remainOfRank(10)}   K剩 ${_remainOfRank(13)}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              const Text('我手牌', style: TextStyle(color: Colors.white, fontSize: 12)),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                icon: const Icon(Icons.remove_circle, color: Colors.white, size: 18),
                onPressed: () => setState(() => _myHand = (_myHand - 1).clamp(0, _total)),
              ),
              Text('$_myHand', style: const TextStyle(color: Colors.white, fontSize: 14)),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                onPressed: () => setState(() => _myHand = (_myHand + 1).clamp(0, _total)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _ovBtn('记一张', Icons.add, () => setState(() => _input = true)),
              _ovBtn('撤销', Icons.undo, _undoOne),
              _ovBtn('重置', Icons.refresh, _reset),
            ]),
          ],
        ),
      );

  Widget _ovBtn(String label, IconData icon, VoidCallback onTap) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Icon(icon, color: Colors.white, size: 16),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
          ),
        ),
      );

  Widget _buildInputCard() => Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        width: 348,
        decoration: BoxDecoration(
          color: Colors.teal.shade800.withOpacity(0.96),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('记打出的牌', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _input = false),
                child: const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
              ),
            ]),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _suitTab(Suit.spade),
                _suitTab(Suit.heart),
                _suitTab(Suit.club),
                _suitTab(Suit.diamond),
                _suitTab(Suit.joker),
              ]),
            ),
            const SizedBox(height: 8),
            _activeSuit == Suit.joker ? _jokerGrid() : _rankGrid(),
            const SizedBox(height: 6),
            Text('点一下就记 1 张 · 已记 ${_seenCount}/$_total',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );

  Widget _suitTab(Suit s) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(s == Suit.joker ? '王' : suitName(s),
              style: TextStyle(color: _activeSuit == s ? Colors.white : _suitColor(s))),
          selected: _activeSuit == s,
          selectedColor: Colors.teal.shade400,
          onSelected: (_) => setState(() => _activeSuit = s),
        ),
      );

  Widget _rankGrid() {
    final suits = [_activeSuit];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in List<int>.generate(13, (i) => i + 3))
          for (final s in suits)
            _cardBtn(CardType(s, r, '${suitName(s)}${rankName(r)}')),
      ],
    );
  }

  Widget _jokerGrid() => Row(
        children: [
          _cardBtn(CardType(Suit.joker, 16, '小王')),
          const SizedBox(width: 8),
          _cardBtn(CardType(Suit.joker, 17, '大王')),
        ],
      );

  Widget _cardBtn(CardType t) {
    final n = _seen[t.key] ?? 0;
    return InkWell(
      onTap: () => _add(t),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.teal.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(t.label,
              style: TextStyle(color: _suitColor(t.suit), fontSize: 14, fontWeight: FontWeight.bold)),
          if (n > 0)
            Text('已记$n', style: const TextStyle(color: Colors.yellow, fontSize: 10)),
        ]),
      ),
    );
  }
}
