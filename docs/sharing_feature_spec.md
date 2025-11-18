# 📤 単語共有機能 - 技術仕様書

Version 3.0で実装予定のコミュニティ機能の詳細設計

---

## 📋 目次

1. [機能概要](#機能概要)
2. [ユーザーストーリー](#ユーザーストーリー)
3. [技術アーキテクチャ](#技術アーキテクチャ)
4. [データモデル](#データモデル)
5. [API設計](#api設計)
6. [UI/UX設計](#uiux設計)
7. [セキュリティ](#セキュリティ)
8. [実装フェーズ](#実装フェーズ)

---

## 🎯 機能概要

### コアコンセプト
「ユーザーが作成した単語セットを共有し、みんなで学び合う」

### 主要機能
1. **単語セットの公開・共有**
2. **コミュニティ単語帳の閲覧・ダウンロード**
3. **ランキング・評価システム**
4. **ソーシャル学習機能**

---

## 👤 ユーザーストーリー

### Story 1: 単語セットの共有
```
As a ユーザー（単語セット作成者）
I want to 自分が作成した単語セットを他のユーザーと共有したい
So that 同じ目標を持つ人の役に立てる
```

**受入基準:**
- [ ] 単語セットにタイトル、説明、カテゴリを設定できる
- [ ] 公開/非公開を切り替えられる
- [ ] 共有リンクまたはQRコードを生成できる
- [ ] 共有した単語セットの統計（ダウンロード数、評価）を確認できる

### Story 2: 単語セットの発見
```
As a ユーザー（学習者）
I want to 人気の単語セットを見つけてダウンロードしたい
So that 効率的に学習できる
```

**受入基準:**
- [ ] カテゴリ別に単語セットを閲覧できる
- [ ] キーワード検索ができる
- [ ] ランキング順、評価順、新着順でソートできる
- [ ] ダウンロード前にプレビューできる

### Story 3: コミュニティ評価
```
As a ユーザー
I want to 使った単語セットを評価・レビューしたい
So that 他の学習者の参考になる
```

**受入基準:**
- [ ] 5段階評価ができる
- [ ] コメントを投稿できる
- [ ] 役立った/役立たないボタンがある
- [ ] 不適切なコンテンツを報告できる

---

## 🏗️ 技術アーキテクチャ

### システム構成図

```
[Flutter App]
    ↓
[Firebase Auth] ← 認証
    ↓
[Cloud Firestore] ← データベース
    ├─ users/
    ├─ vocabulary_sets/
    ├─ reviews/
    └─ reports/
    ↓
[Cloud Functions] ← ビジネスロジック
    ├─ onSetPublished (通知・集計)
    ├─ onReviewCreated (スパム検出)
    └─ moderateContent (コンテンツ審査)
    ↓
[Firebase Storage] ← 画像・音声（将来）
```

### 技術スタック

| レイヤー | 技術 | 用途 |
|---------|------|------|
| フロントエンド | Flutter 3.x | UIレンダリング |
| 状態管理 | Riverpod / Bloc | 複雑な状態管理 |
| 認証 | Firebase Auth | ユーザー管理 |
| データベース | Cloud Firestore | NoSQLデータベース |
| ストレージ | Firebase Storage | メディアファイル |
| サーバーレス | Cloud Functions | バックエンドロジック |
| 検索 | Algolia（オプション） | 高度な検索 |
| 分析 | Firebase Analytics | 使用状況分析 |

---

## 📊 データモデル

### 1. VocabularySet（単語セット）

```dart
class VocabularySet {
  String id;                    // 一意のID
  String title;                 // セット名（例: "TOEIC頻出300語"）
  String description;           // 説明文
  String category;              // カテゴリ（TOEIC, 英検, ビジネスなど）
  List<String> tags;            // タグ（#初心者, #上級者など）
  String creatorId;             // 作成者のユーザーID
  String creatorName;           // 作成者の表示名
  bool isPublic;                // 公開/非公開
  int vocabularyCount;          // 単語数
  int downloadCount;            // ダウンロード数
  double averageRating;         // 平均評価（0-5）
  int reviewCount;              // レビュー数
  DateTime createdAt;           // 作成日時
  DateTime updatedAt;           // 更新日時
  List<VocabularyItem> items;   // 単語リスト
}

class VocabularyItem {
  String english;               // 英単語
  String japanese;              // 日本語訳
  String? example;              // 例文（オプション）
  String? imageUrl;             // 画像URL（オプション）
}
```

**Firestoreパス:** `vocabulary_sets/{setId}`

### 2. User（ユーザー）

```dart
class User {
  String id;                    // ユーザーID（Firebase Auth UID）
  String displayName;           // 表示名
  String? photoUrl;             // プロフィール画像URL
  String? bio;                  // 自己紹介
  int createdSetsCount;         // 作成した単語セット数
  int totalDownloads;           // 合計ダウンロード数
  int followersCount;           // フォロワー数
  int followingCount;           // フォロー中の数
  DateTime createdAt;           // アカウント作成日
  List<Achievement> badges;     // 獲得バッジ
}
```

**Firestoreパス:** `users/{userId}`

### 3. Review（レビュー）

```dart
class Review {
  String id;                    // レビューID
  String setId;                 // 単語セットID
  String userId;                // レビュー投稿者ID
  String userName;              // 投稿者名
  int rating;                   // 評価（1-5）
  String? comment;              // コメント（オプション）
  int helpfulCount;             // 役立った数
  DateTime createdAt;           // 投稿日時
  bool isFlagged;               // 報告されているか
}
```

**Firestoreパス:** `vocabulary_sets/{setId}/reviews/{reviewId}`

### 4. UserSetRelation（ユーザーと単語セットの関係）

```dart
class UserSetRelation {
  String userId;                // ユーザーID
  String setId;                 // 単語セットID
  bool isDownloaded;            // ダウンロード済みか
  bool hasReviewed;             // レビュー済みか
  DateTime? downloadedAt;       // ダウンロード日時
  int studyProgress;            // 学習進捗（%）
  int correctCount;             // 正解数
  int wrongCount;               // 不正解数
}
```

**Firestoreパス:** `users/{userId}/downloaded_sets/{setId}`

---

## 🔌 API設計

### REST風のFirestore操作

#### 1. 単語セットを公開する

```dart
Future<String> publishVocabularySet({
  required String title,
  required String description,
  required String category,
  required List<String> tags,
  required List<VocabularyItem> items,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('ログインが必要です');

  final setRef = FirebaseFirestore.instance
      .collection('vocabulary_sets')
      .doc();

  final vocabularySet = VocabularySet(
    id: setRef.id,
    title: title,
    description: description,
    category: category,
    tags: tags,
    creatorId: user.uid,
    creatorName: user.displayName ?? '匿名',
    isPublic: true,
    vocabularyCount: items.length,
    downloadCount: 0,
    averageRating: 0,
    reviewCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: items,
  );

  await setRef.set(vocabularySet.toJson());
  
  // Cloud Functionでカウント更新
  // ユーザーのcreatedSetsCountをインクリメント
  
  return setRef.id;
}
```

#### 2. 単語セットを検索する

```dart
Future<List<VocabularySet>> searchVocabularySets({
  String? category,
  String? keyword,
  SortBy sortBy = SortBy.popular,
  int limit = 20,
}) async {
  var query = FirebaseFirestore.instance
      .collection('vocabulary_sets')
      .where('isPublic', isEqualTo: true);

  // カテゴリフィルター
  if (category != null) {
    query = query.where('category', isEqualTo: category);
  }

  // ソート
  switch (sortBy) {
    case SortBy.popular:
      query = query.orderBy('downloadCount', descending: true);
      break;
    case SortBy.rating:
      query = query.orderBy('averageRating', descending: true);
      break;
    case SortBy.newest:
      query = query.orderBy('createdAt', descending: true);
      break;
  }

  query = query.limit(limit);

  final snapshot = await query.get();
  return snapshot.docs
      .map((doc) => VocabularySet.fromJson(doc.data()))
      .toList();
}
```

#### 3. 単語セットをダウンロードする

```dart
Future<void> downloadVocabularySet(String setId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('ログインが必要です');

  // トランザクションでダウンロード数をインクリメント
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final setRef = FirebaseFirestore.instance
        .collection('vocabulary_sets')
        .doc(setId);
    
    final snapshot = await transaction.get(setRef);
    final newDownloadCount = (snapshot.data()?['downloadCount'] ?? 0) + 1;
    
    transaction.update(setRef, {'downloadCount': newDownloadCount});
    
    // ユーザーのダウンロード履歴に追加
    final userSetRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('downloaded_sets')
        .doc(setId);
    
    transaction.set(userSetRef, {
      'setId': setId,
      'downloadedAt': FieldValue.serverTimestamp(),
      'studyProgress': 0,
    });
  });
  
  // ローカルにも保存（Hive）
  final set = await getVocabularySet(setId);
  await _saveToLocalStorage(set);
}
```

#### 4. レビューを投稿する

```dart
Future<void> postReview({
  required String setId,
  required int rating,
  String? comment,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('ログインが必要です');

  final reviewRef = FirebaseFirestore.instance
      .collection('vocabulary_sets')
      .doc(setId)
      .collection('reviews')
      .doc();

  final review = Review(
    id: reviewRef.id,
    setId: setId,
    userId: user.uid,
    userName: user.displayName ?? '匿名',
    rating: rating,
    comment: comment,
    helpfulCount: 0,
    createdAt: DateTime.now(),
    isFlagged: false,
  );

  await reviewRef.set(review.toJson());
  
  // Cloud Functionで平均評価を再計算
}
```

---

## 🎨 UI/UX設計

### 画面構成

#### 1. コミュニティタブ（新規）

```
[ホーム] [単語帳] [テスト] [コミュニティ] ← 4つ目のタブを追加
```

#### 2. コミュニティトップ画面

```
┌─────────────────────────────┐
│ 🔥 人気の単語セット         │
│ ┌─────────────────────────┐ │
│ │ TOEIC頻出300語          │ │
│ │ by 太郎                 │ │
│ │ ⭐4.8 | 📥1,234         │ │
│ └─────────────────────────┘ │
│                             │
│ 📚 カテゴリで探す           │
│ [TOEIC] [英検] [受験]       │
│ [ビジネス] [日常会話]       │
│                             │
│ 🆕 新着の単語セット         │
│ ...                         │
└─────────────────────────────┘
```

#### 3. 単語セット詳細画面

```
┌─────────────────────────────┐
│ ← TOEIC頻出300語            │
│                             │
│ by 太郎                     │
│ ⭐⭐⭐⭐⭐ 4.8 (123件)       │
│                             │
│ 📝 説明                     │
│ TOEICテストで頻出する       │
│ 300語を厳選しました         │
│                             │
│ 📊 詳細                     │
│ • 単語数: 300語             │
│ • ダウンロード: 1,234回     │
│ • カテゴリ: TOEIC           │
│                             │
│ [📥 ダウンロード]           │
│ [👁️ プレビュー]            │
│                             │
│ 💬 レビュー (123)           │
│ ┌───────────────────────┐   │
│ │ ⭐⭐⭐⭐⭐              │   │
│ │ 花子 • 2日前           │   │
│ │ とても役立ちました！   │   │
│ │ 👍 役立った (12)       │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

#### 4. マイページに「公開した単語セット」タブを追加

```
┌─────────────────────────────┐
│ マイページ                   │
│                             │
│ [学習中] [作成した] [公開した]│
│                             │
│ 公開した単語セット (3)       │
│ ┌─────────────────────────┐ │
│ │ TOEIC頻出300語          │ │
│ │ 📥1,234 | ⭐4.8         │ │
│ │ [統計を見る] [編集]     │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 🔒 セキュリティ

### 1. 認証・認可

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 単語セット
    match /vocabulary_sets/{setId} {
      // 公開セットは誰でも読める
      allow read: if resource.data.isPublic == true;
      // 作成者のみ読み書き可能（非公開）
      allow read, update, delete: if request.auth.uid == resource.data.creatorId;
      // 認証済みユーザーは作成可能
      allow create: if request.auth != null;
      
      // レビュー
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth.uid == resource.data.userId;
      }
    }
    
    // ユーザー情報
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

### 2. コンテンツモデレーション

**自動フィルタリング:**
- NGワードリスト（不適切な言葉）
- スパム検出（同じ内容の連投）

**手動モデレーション:**
- ユーザーからの報告機能
- 管理者ダッシュボードで審査

**Cloud Function例:**
```javascript
exports.moderateContent = functions.firestore
  .document('vocabulary_sets/{setId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // NGワードチェック
    const hasInappropriateWords = checkForBadWords(data.title + data.description);
    
    if (hasInappropriateWords) {
      // 自動的に非公開に
      await snap.ref.update({ isPublic: false, flaggedForReview: true });
      // 管理者に通知
      await sendAdminNotification(snap.id);
    }
  });
```

### 3. レート制限

- 単語セット公開: 1日5個まで
- レビュー投稿: 1セットあたり1回まで
- ダウンロード: 制限なし

---

## 🚀 実装フェーズ

### Phase 1: 基本機能（1-2ヶ月）

- [ ] Firebase Auth統合
- [ ] Firestore設定
- [ ] 単語セット公開機能
- [ ] 共有リンク生成
- [ ] 単語セット検索・閲覧
- [ ] ダウンロード機能

### Phase 2: コミュニティ機能（1ヶ月）

- [ ] レビュー・評価システム
- [ ] ランキング表示
- [ ] カテゴリ分類
- [ ] タグ機能

### Phase 3: ソーシャル機能（1ヶ月）

- [ ] ユーザープロフィール
- [ ] フォロー機能
- [ ] 通知機能
- [ ] マイページ拡張

### Phase 4: セキュリティ・品質向上（継続）

- [ ] コンテンツモデレーション
- [ ] 報告機能
- [ ] レート制限
- [ ] パフォーマンス最適化

---

## 💰 コスト試算

### Firebase料金（Spark Plan → Blaze Plan）

**想定:** ユーザー10,000人、アクティブユーザー3,000人/月

| 項目 | 使用量 | 料金 |
|-----|--------|------|
| Cloud Firestore 読み取り | 500,000回/月 | $0.06/100k → **$0.30** |
| Cloud Firestore 書き込み | 100,000回/月 | $0.18/100k → **$0.18** |
| Cloud Storage | 5GB | $0.026/GB → **$0.13** |
| Cloud Functions | 50万回呼び出し | 200万回まで無料 → **$0** |
| Firebase Auth | 無料 | **$0** |

**月額合計: 約$0.61（約90円）**

※ ユーザー数に応じて増加

---

## 📈 成功指標（KPI）

| 指標 | 目標値（3ヶ月後） |
|-----|-----------------|
| 公開された単語セット数 | 500+ |
| 合計ダウンロード数 | 5,000+ |
| アクティブ投稿者 | 50+ |
| 平均レビュー数/セット | 3+ |
| ユーザーエンゲージメント率 | 40%+ |

---

**最終更新:** 2024年11月
**次回レビュー:** Version 2.0リリース後

