// 全局单例：对局状态、模板库、导航 Key
// 这类小工具 App 用全局单例最省事，避免层层传参。
import 'package:flutter/material.dart';
import 'state/game_state.dart';
import 'services/template_store.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 四人三副牌（162 张）。如以后玩两副，把 decks 改成 2 即可。
final GameState gameState = GameState(decks: 3);

// 模板库：保存 54 种牌的样图路径
final TemplateStore templateStore = TemplateStore();
