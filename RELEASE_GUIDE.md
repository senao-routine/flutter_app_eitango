# 📱 アプリリリース完全ガイド

英単語学習アプリをiOS/Androidでリリースするための手順書

---

## 🎯 リリース前チェックリスト

### Phase 1: 基本設定（必須）

- [ ] **アプリ名の決定**
  - 候補: 「英単語学習」「英単語マスター」「Eitango」など
  - 日本市場向けなら日本語名を推奨

- [ ] **アプリアイコンの作成**
  - サイズ: 1024x1024px
  - ツール: Canva、Figma、Adobe Illustratorなど
  - flutter_launcher_icons パッケージで自動生成可能

- [ ] **プライバシーポリシーの作成**
  - テンプレートは `docs/privacy_policy_template.md` を参照
  - 公開場所: GitHub Pages、自社サイト、Google Sitesなど

- [ ] **データエクスポート/インポート機能の実装**
  - 機種変更時のデータ移行を可能にする
  - JSON/CSV形式でのバックアップ

---

## 🤖 Android向け準備

### 1. Google Play Consoleアカウント作成
- 費用: $25（初回のみ、生涯有効）
- URL: https://play.google.com/console/signup

### 2. Application IDの変更

現在: `com.example.english_vocab_app`
変更先: `com.yourcompany.eitango`（独自のものに）

**変更箇所:**
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    applicationId = "com.yourcompany.eitango"  // ← 変更
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

### 3. 署名鍵（Keystore）の作成

**重要:** この鍵は一度作成したら絶対に紛失しないこと！

```bash
# コマンドで作成
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# パスワードと情報を入力（必ずメモ！）
```

**key.properties ファイルを作成:**
```
# android/key.properties
storePassword=<作成したパスワード>
keyPassword=<作成したパスワード>
keyAlias=upload
storeFile=/Users/yourname/upload-keystore.jks
```

**build.gradle.kts を更新:**
```kotlin
// 署名設定を追加
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. ビルドとリリース

```bash
# Releaseビルドを作成
flutter build appbundle --release

# 生成ファイル: build/app/outputs/bundle/release/app-release.aab
```

### 5. Google Play Consoleでの設定

1. **アプリを作成**
   - アプリ名、デフォルト言語、アプリ/ゲームを選択

2. **ストア掲載情報**
   - 簡単な説明（80文字）
   - 詳細な説明（4000文字）
   - スクリーンショット（2-8枚）
     - 最小: 320px
     - 最大: 3840px
     - 推奨: 1080 x 1920px (9:16)

3. **コンテンツレーティング**
   - アンケートに回答（教育アプリ）

4. **ターゲット層**
   - 13歳以上を推奨

5. **プライバシーポリシー**
   - URLを入力（必須）

6. **アプリのリリース**
   - 製品版トラック > AABファイルをアップロード
   - 審査には1-3日かかる

---

## 🍎 iOS向け準備

### 1. Apple Developer Programに登録
- 費用: 12,980円/年
- URL: https://developer.apple.com/programs/

### 2. Bundle Identifierの変更

現在: デフォルト設定
変更先: `com.yourcompany.eitango`

**Xcodeでの変更手順:**
1. `ios/Runner.xcworkspace` をXcodeで開く
2. Runner > General > Bundle Identifier を変更
3. Signing & Capabilities > Team を選択

**または、Info.plistで直接変更:**
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleDisplayName</key>
<string>英単語学習</string>  <!-- アプリ名 -->
```

### 3. Signing & Capabilitiesの設定

Xcodeで:
1. Runner > Signing & Capabilities
2. Automatically manage signing をチェック
3. Team を選択（Apple Developer Account）

### 4. ビルドとアーカイブ

```bash
# Releaseビルドを作成
flutter build ios --release

# Xcodeでアーカイブ
# Xcode > Product > Archive > Distribute App
```

### 5. App Store Connectでの設定

1. **アプリを作成**
   - App Store Connect にログイン
   - マイApp > 新規App

2. **App情報**
   - アプリ名
   - プライバシーポリシーURL
   - カテゴリ: 教育

3. **スクリーンショット**
   必須サイズ:
   - 6.5インチ (iPhone 14 Pro Max): 1284 x 2778px
   - 5.5インチ (iPhone 8 Plus): 1242 x 2208px

4. **説明文**
   - プロモーションテキスト（170文字）
   - 説明（4000文字）
   - キーワード（100文字）

5. **審査情報**
   - デモアカウント（必要なら）
   - レビュー用の注記

6. **アプリのリリース**
   - Xcodeからアップロード
   - 審査には1-3日かかる

---

## 📸 スクリーンショット作成のコツ

### ツール
- iOS Simulator + Command + S
- Android Emulator + Screenshot
- デザインツール: Figma, Canvaで装飾

### 推奨構成（3-5枚）
1. **メイン画面** - 単語帳リスト
2. **検索・フィルター機能**
3. **単語追加画面**
4. **テスト画面**
5. **統計・正答率表示**

### Tips
- 明るい背景
- デモデータを充実させる
- 機能説明のテキストオーバーレイ

---

## 📝 アプリ説明文のテンプレート

### 簡単な説明（80文字）
```
自分だけの単語帳で効率的に英語学習！4択テストで楽しく復習できる英単語学習アプリ
```

### 詳細な説明
```
■ こんな方におすすめ
・TOEIC、英検、受験勉強中の方
・自分だけのオリジナル単語帳が欲しい方
・スキマ時間に効率的に英語学習したい方

■ 主な機能
【単語帳】
・英単語と日本語訳を簡単に登録
・検索機能で素早く単語を見つける
・正答率でフィルタリング（苦手な単語を集中学習）
・スワイプで削除

【テスト機能】
・4択問題で楽しく学習
・5問、10問、20問、全問から選択可能
・正答率を自動記録
・苦手な単語を可視化

【統計機能】
・各単語の正答数・誤答数を記録
・正答率を色分けして表示
・学習の進捗を一目で確認

■ 特徴
✓ 完全無料
✓ オフラインで使用可能
✓ シンプルで使いやすいデザイン
✓ 広告なし（現在）
```

---

## ⚠️ よくある審査の却下理由

### 1. プライバシーポリシーがない
**対策:** 必ず公開URLを用意する

### 2. メタデータが不十分
**対策:** 説明文とスクリーンショットを充実させる

### 3. クラッシュする
**対策:** 実機でテストを十分に行う

### 4. コンテンツレーティングが不適切
**対策:** 正直にアンケートに回答

---

## 💰 必要なコスト

| 項目 | iOS | Android | 備考 |
|------|-----|---------|------|
| デベロッパー登録 | 12,980円/年 | $25（初回のみ） | 必須 |
| サーバー | 0円 | 0円 | v1.0はローカルストレージのみ |
| ドメイン（プライバシーポリシー用） | 0-1,000円/年 | 0-1,000円/年 | GitHub Pages利用で無料 |

**初年度合計: 約14,000円**

---

## 📅 推奨スケジュール

| 期間 | タスク |
|------|--------|
| Week 1 | アイコン・アプリ名決定、プライバシーポリシー作成 |
| Week 2 | Application ID変更、署名設定、データエクスポート機能実装 |
| Week 3 | スクリーンショット作成、説明文作成 |
| Week 4 | ビルド・アップロード、審査提出 |

---

## 🎓 参考リンク

### 公式ドキュメント
- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Flutter: Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

### ツール
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) - アイコン自動生成
- [App Icon Generator](https://appicon.co/) - アイコン生成ツール

### テンプレート
- [Privacy Policy Generator](https://app-privacy-policy-generator.nisrulz.com/)

---

## 📞 サポート

問題が発生した場合:
1. Flutter公式ドキュメントを確認
2. Stack Overflowで検索
3. GitHub Issuesで質問
4. 日本語コミュニティ: Flutter Japan Users Group

