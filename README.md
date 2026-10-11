# 510k 自动记牌器（安卓 · 真·系统悬浮窗版）

> 玩法：四人三副牌（162 张）。本 App 的核心是一个**盖在微信小程序 / 桌面上方的系统级悬浮窗**：开局把整张截屏交给 App 识别你的手牌，之后对战过程**直接在悬浮窗里点牌录入"打出的牌"**，全程不用切回 App。
>
> ⚠️ 注意：**网页版做不到"盖在其他 App 上的悬浮窗"**——这是浏览器/操作系统的硬限制。你想要"退出网页后、在游戏或桌面上还能显示并操作"，必须用本原生安卓 App（下面的方案）。

## 一、使用流程

1. **录入牌样（一次性）**
   - 打开 App → 「管理牌样（模板）」→ 54 种牌每种传一张清晰样图（牌面占满、背景干净）。
   - 进度显示 `X / 54`，填满后才能识别。

2. **开局识别（整张截屏，不裁切）**
   - 在微信小程序里截一张整屏 → 截图预览点「分享」选本 App，或首页「导入一张对局截图」从相册选。
   - App 自动识别你的手牌，识别页可点掉误认的牌，计数随之更新。

3. **启动对战悬浮窗（核心）**
   - 识别页点「启动对战悬浮窗（返回游戏）」→ App 退到后台，悬浮窗浮在游戏画面上方。
   - 之后**全程在悬浮窗里操作**：
     - 顶部显示：已出 / 共 / 剩余未知、对手合计剩、5·10·K 各自剩余。
     - 「我手牌」用 −/+ 填你已知的自己手牌数，对手剩余会自动扣减。
     - 点「记一张」→ 选 花色→点数 → 每点一下记 1 张（含大小王），计数实时更新。
     - 「撤销」回退上一张、「重置」清空本局。
   - 悬浮窗可拖动、盖在微信小程序**和桌面（手机主屏）之上**，关 App 也在。右上角 ✕ 关闭。
   - 下次直接开 App 点「启动对战悬浮窗（浮在游戏上）」即可，开局识别结果会从共享存储自动读回。

3. **看懂计数**
   - `剩余未知 = 162 − 累计已见`（全场还没露过面的牌）。
   - `对手合计剩余 = 剩余未知 − 我手牌`（三家对手手里还剩的牌）。
   - `关键牌剩余`：5/10/K 各自还剩几张，判断大牌是否还在外面。

## 二、本地运行 / 打包（安卓 APK）

> 本专家只做本地打包指引，不负责应用商店上架。
> 当前沙箱环境缺少 Flutter/Android 工具链且安卓依赖仓库(maven.google.com)不可达，**无法在此直接编译 APK**，请按下面方式在本地或云端构建。

### 环境准备
- 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)（≥3.22），并 `flutter doctor` 通过安卓项。
- 安装 Android Studio + Android SDK + 命令行工具（Command-line Tools）。

### 生成原生脚手架并合并清单
本项目只给了 `lib/`、`pubspec.yaml` 和安卓清单（不含 Gradle 脚手架与图标资源），所以**必须先让 Flutter 补齐原生工程**，再把我们的定制清单覆盖回去（`flutter create` 会生成默认清单并覆盖我们的）：

```bash
cd 510k-counter
flutter create --platforms=android .     # 生成 build.gradle / gradle wrapper / res 图标 等
```

> ⚠️ 上面这步会把 `android/app/src/main/AndroidManifest.xml` 覆盖成默认版。请用下面「清单全文」**整文件替换**它（直接粘贴覆盖即可，已包含悬浮窗权限、分享接收、OverlayService）。

**清单全文** —— 把 `android/app/src/main/AndroidManifest.xml` 整个内容换成：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 悬浮窗所需权限 -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <application
        android:label="510k记牌器"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- 接收从相册/截图"分享"进来的图片（记牌器核心入口） -->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <!-- flutter_overlay_window 所需的悬浮窗前台服务 -->
        <service
            android:name="flutter.overlay.window.flutter_overlay_window.OverlayService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="510k 记牌器悬浮窗显示对局计数" />
        </service>
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

> 替换后，`MainActivity.kt` 用 `flutter create` 生成的默认版即可（标准 `FlutterActivity`，分享接收由插件处理），无需改动。

### 获取依赖 & 编译
```bash
flutter pub get
flutter run            # 连上安卓手机/模拟器直接调试
flutter build apk      # 生成 release APK，在 build/app/outputs/flutter-apk/app-release.apk
```

### 真机安装
把 `app-release.apk` 传到手机，允许"未知来源"安装即可（无需商店）。

### 常见报错
- `cmdline-tools not found`：Android Studio → SDK Manager → 装 "Command-line Tools"。
- `Gradle build failed`：先 `flutter clean` 再重试。
- 分享列表里找不到本 App：确认清单里已加 SEND / SEND_MULTIPLE 两个 intent-filter，并重新 `flutter build`。
- 识别很慢/卡：截屏时裁小牌面区域；或在 `lib/services/recognizer.dart` 调大 `step`、减少 `scales`。

## 三、识别调优（真机必调）

识别用「灰度模板匹配 + 归一化互相关 + 非极大值抑制」，参数都在 `lib/services/recognizer.dart`：

- `threshold = 0.82`：太低误报、太高漏报，按你的牌面清晰度微调。
- `scales` / `step`：影响召回与速度。
- 样图质量最关键：每种牌截一张清晰、牌面占满的图，识别率立刻上档次。

> 性能敏感时可把 `recognize()` 用 `compute()` 丢进 isolate（避免卡 UI）；若要更快更准，可后续替换为 OpenCV（平台通道调用 C++）或 TensorFlow Lite 模型。

## 四、真·系统悬浮窗（盖在游戏画面 / 桌面上，且可操作）

本 App 的悬浮窗是**独立引擎运行的系统级窗口**：它自己持有对局状态，不仅能显示计数，还能**直接点牌录入"打出的牌"**，盖在微信小程序和手机桌面之上，关掉主 App 也一直在。

- 首页点「启动对战悬浮窗（浮在游戏上）」：首次跳到系统"在其他应用上层显示"开关，打开授权；之后悬浮窗出现、可拖动。
- 识别页点「启动对战悬浮窗（返回游戏）」：把开局识别结果写入共享存储并拉起悬浮窗，再把 App 退到后台，只留悬浮窗 + 游戏画面。
- 悬浮窗内可直接「记一张 / 撤销 / 重置」，并显示 剩余未知 / 对手合计剩 / 5·10·K 剩余 / 我手牌。
- 右上角 ✕ 关闭；首页再点一次也可关闭。
- 状态持久化在 `shared_preferences`，重开悬浮窗会读回上次进度。

> 依赖 `flutter_overlay_window`（悬浮窗 UI 在 `lib/overlay/overlay_entry.dart`，自包含状态逻辑）+ `shared_preferences`（跨引擎共享开局识别结果）。`AndroidManifest.xml` 已配置 `SYSTEM_ALERT_WINDOW` 等权限及 `OverlayService`；`compileSdk` 需 ≥ 34（Flutter 3.22+ 默认满足）。

## 五、已知边界与风险

- **黑屏风险**：若微信小程序开启了"安全 surface"，系统截屏/分享拿到的可能是黑屏，识别会失败。只能真机试；若中招，目前只能换"手动逐张点选记牌"方案。
- **灰帽提示**：自动辅助可能触发游戏反作弊，本工具仅供技术研究与娱乐，**不建议用于排位/比赛**，账号风险自负。
- 四人三副为默认；玩两副改 `lib/globals.dart` 里 `GameState(decks: 2)`。
- iOS：当前仅安卓；iOS 无系统级悬浮窗，且分享接收机制不同，需另行适配。

## 六、目录结构

```
lib/
  globals.dart                全局单例（状态/模板/导航）
  main.dart                   入口 + 监听分享截图
  models/card_model.dart      牌模型（含 5/10/K 计分标记）
  models/deck.dart            生成 54 种牌
  state/game_state.dart       计数核心（已见并集、剩余计算）
  services/template_store.dart 模板样图存储
  services/recognizer.dart    模板匹配识别引擎
  widgets/summary_bar.dart    悬浮栏（实时牌局信息）
  screens/home_screen.dart     首页（含悬浮窗开关）
  screens/template_screen.dart 模板录入
  screens/result_screen.dart  识别结果 + 明细（含"返回游戏"按钮）
  overlay/overlay_entry.dart  系统悬浮窗 UI（overlayMain 入口）
  services/overlay_service.dart 悬浮窗显隐/推数逻辑
android/...                   安卓原生（含分享 intent-filter + 悬浮窗服务）
```
