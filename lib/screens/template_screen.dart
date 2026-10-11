// 模板录入页：把 54 种牌各传一张样图
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../globals.dart';
import '../models/deck.dart';

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});
  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  final types = buildDeckTypes();

  Future<void> _pick(CardType t) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      await templateStore.setTemplate(t, File(img.path));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('录入牌样模板')),
        body: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 0.8),
          itemCount: types.length,
          itemBuilder: (_, i) {
            final t = types[i];
            final p = templateStore.templatePaths[t.key];
            final has = p != null && p.isNotEmpty;
            return InkWell(
              onTap: () => _pick(t),
              child: Column(children: [
                Expanded(
                    child: has
                        ? Image.file(File(p!), fit: BoxFit.contain)
                        : Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)))),
                Text(t.label, style: const TextStyle(fontSize: 12)),
              ]),
            );
          },
        ),
      );
}
