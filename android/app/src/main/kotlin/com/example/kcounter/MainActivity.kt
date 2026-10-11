package com.example.kcounter

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // 默认 Flutter Activity 即可，分享图片的接收由 receive_sharing_intent 插件处理。
    // 如需"真·系统悬浮窗"（盖在游戏画面上方），后续可在这里接入 flutter_overlay_window，
    // 并把 SummaryBar 的内容推到悬浮窗里展示。
}
