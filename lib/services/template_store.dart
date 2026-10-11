// 模板库：保存用户提前录入的 54 种牌样图
// 识别时把截图和这些样图做比对。样图质量直接决定识别率，
// 建议每种牌截一张清晰、牌面占满的图片。
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';
import '../models/deck.dart';

class TemplateStore {
  final Map<String, String> templatePaths = {}; // cardKey -> 样图文件路径
  late Directory dir;

  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    dir = Directory('${appDir.path}/templates');
    if (!await dir.exists()) await dir.create(recursive: true);

    final idxFile = File('${dir.path}/index.json');
    if (await idxFile.exists()) {
      final map = jsonDecode(await idxFile.readAsString()) as Map;
      templatePaths.addAll(map.map((k, v) => MapEntry(k, v as String)));
    }
    // 补齐未记录的牌种
    for (final t in buildDeckTypes()) {
      templatePaths.putIfAbsent(t.key, () => '');
    }
  }

  Future<void> setTemplate(CardType t, File image) async {
    final dest = File('${dir.path}/${t.key}.png');
    await image.copy(dest.path);
    templatePaths[t.key] = dest.path;
    await _saveIndex();
  }

  bool get isComplete => templatePaths.values.every((p) => p.isNotEmpty);
  int get filledCount =>
      templatePaths.values.where((p) => p.isNotEmpty).length;

  Future<void> _saveIndex() async {
    final f = File('${dir.path}/index.json');
    await f.writeAsString(jsonEncode(templatePaths));
  }
}
