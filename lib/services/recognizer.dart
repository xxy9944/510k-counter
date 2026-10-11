// 识别引擎：模板匹配
//
// 原理：把每张样图和你截屏都转成"归一化尺寸的灰度图"，
// 在截屏上多尺度滑动窗口搜索，和每种样图算"归一化互相关(NCC)"相似度，
// 超过阈值就记一次命中，再做非极大值抑制(NMS)去重，最后统计每种牌命中几张。
//
// ⚠️ 调优提示（真机上大概率要调）：
//  - threshold(0.82) 太低会误报、太高会漏报，按你的牌面清晰度调。
//  - scales/step 影响速度与召回，卡顿就调大 step。
//  - 真机建议只截"牌面区域"（用系统编辑裁掉多余画面），能大幅提速提准。
//  - 性能敏感可把 recognize 包进 isolate（详见 README）。
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import '../models/card_model.dart';
import '../models/deck.dart';
import 'template_store.dart';

class _Det {
  final String key;
  final double score;
  final int x, y, w, h;
  _Det(this.key, this.score, this.x, this.y, this.w, this.h);
}

Future<Map<String, int>> recognize(File shot, TemplateStore store) async {
  final image = img.decodeImage(await shot.readAsBytes());
  if (image == null) return {};

  // 归一化尺寸：所有样图与窗口都缩到这尺寸再比
  const normW = 40, normH = 56;

  // 预计算样图灰度
  final templates = <String, List<double>>{};
  for (final t in buildDeckTypes()) {
    final p = store.templatePaths[t.key];
    if (p == null || p.isEmpty) continue;
    final tmpl = img.decodeImage(await File(p).readAsBytes());
    if (tmpl == null) continue;
    templates[t.key] = _grayNorm(tmpl, normW, normH);
  }
  if (templates.isEmpty) return {};

  final candidates = <_Det>[];
  const scales = [0.6, 0.8, 1.0, 1.3];
  const step = 4;
  const threshold = 0.82;

  for (final s in scales) {
    final w = (normW * s).round(), h = (normH * s).round();
    if (w > image.width || h > image.height) continue;
    for (int y = 0; y + h <= image.height; y += step) {
      for (int x = 0; x + w <= image.width; x += step) {
        final win = _grayNorm(_crop(image, x, y, w, h), normW, normH);
        String bestKey = '';
        double best = -2;
        templates.forEach((k, t) {
          final c = _corr(win, t);
          if (c > best) {
            best = c;
            bestKey = k;
          }
        });
        if (best > threshold) candidates.add(_Det(bestKey, best, x, y, w, h));
      }
    }
  }

  // 非极大值抑制：去掉重叠的重复命中
  candidates.sort((a, b) => b.score.compareTo(a.score));
  final kept = <_Det>[];
  for (final c in candidates) {
    bool ok = true;
    for (final k in kept) {
      if (_iou(c, k) > 0.3) {
        ok = false;
        break;
      }
    }
    if (ok) kept.add(c);
  }

  final counts = <String, int>{};
  for (final d in kept) counts[d.key] = (counts[d.key] ?? 0) + 1;
  return counts;
}

// 缩放到 w×h 并取灰度
List<double> _grayNorm(img.Image image, int w, int h) {
  final r = img.copyResize(image, width: w, height: h);
  final out = List<double>.filled(w * h, 0.0);
  int i = 0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = r.getPixel(x, y);
      out[i++] = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
    }
  }
  return out;
}

img.Image _crop(img.Image src, int x, int y, int w, int h) =>
    img.copyCrop(src, x: x, y: y, width: w, height: h);

// 归一化互相关：1=完全一致，-1=完全相反
double _corr(List<double> a, List<double> b) {
  double ma = 0, mb = 0;
  for (int i = 0; i < a.length; i++) {
    ma += a[i];
    mb += b[i];
  }
  ma /= a.length;
  mb /= b.length;
  double num = 0, da = 0, db = 0;
  for (int i = 0; i < a.length; i++) {
    final x = a[i] - ma, y = b[i] - mb;
    num += x * y;
    da += x * x;
    db += y * y;
  }
  if (da == 0 || db == 0) return 0;
  return num / sqrt(da * db);
}

double _iou(_Det a, _Det b) {
  final ix1 = max(a.x, b.x), iy1 = max(a.y, b.y);
  final ix2 = min(a.x + a.w, b.x + b.w), iy2 = min(a.y + a.h, b.y + b.h);
  final iw = max(0, ix2 - ix1), ih = max(0, iy2 - iy1);
  final inter = iw * ih;
  final union = a.w * a.h + b.w * b.h - inter;
  return union <= 0 ? 0 : inter / union;
}
