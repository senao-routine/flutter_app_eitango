import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vocabulary.dart';

class VocabularyProvider with ChangeNotifier {
  late Box<Vocabulary> _vocabularyBox;
  List<Vocabulary> _vocabularies = [];

  List<Vocabulary> get vocabularies => _vocabularies;

  Future<void> initialize() async {
    _vocabularyBox = await Hive.openBox<Vocabulary>('vocabularies');
    _loadVocabularies();
  }

  void _loadVocabularies() {
    _vocabularies = _vocabularyBox.values.toList();
    // 作成日時で降順ソート（新しいものが上）
    _vocabularies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addVocabulary(String english, String japanese) async {
    final vocab = Vocabulary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      english: english,
      japanese: japanese,
      createdAt: DateTime.now(),
    );
    await _vocabularyBox.put(vocab.id, vocab);
    _loadVocabularies();
  }

  Future<void> updateVocabulary(
    String id,
    String english,
    String japanese,
  ) async {
    final vocab = _vocabularyBox.get(id);
    if (vocab != null) {
      vocab.english = english;
      vocab.japanese = japanese;
      await vocab.save();
      _loadVocabularies();
    }
  }

  Future<void> deleteVocabulary(String id) async {
    await _vocabularyBox.delete(id);
    _loadVocabularies();
  }

  Future<void> updateStats(String id, bool isCorrect) async {
    final vocab = _vocabularyBox.get(id);
    if (vocab != null) {
      if (isCorrect) {
        vocab.correctCount++;
      } else {
        vocab.wrongCount++;
      }
      await vocab.save();
      _loadVocabularies();
    }
  }

  // テスト用にランダムな単語を取得
  List<Vocabulary> getRandomVocabularies(int count) {
    if (_vocabularies.isEmpty) return [];
    final shuffled = List<Vocabulary>.from(_vocabularies)..shuffle();
    return shuffled.take(count).toList();
  }

  // データをエクスポート（JSON形式）
  Future<String> exportToJson() async {
    final data = _vocabularies.map((vocab) {
      return {
        'id': vocab.id,
        'english': vocab.english,
        'japanese': vocab.japanese,
        'createdAt': vocab.createdAt.toIso8601String(),
        'correctCount': vocab.correctCount,
        'wrongCount': vocab.wrongCount,
      };
    }).toList();

    final jsonString = jsonEncode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'vocabularyCount': data.length,
      'vocabularies': data,
    });

    return jsonString;
  }

  // データをファイルにエクスポートして共有
  Future<void> exportAndShare() async {
    try {
      // JSONデータを生成
      final jsonString = await exportToJson();

      // 一時ファイルに保存
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/eitango_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // ファイルを共有
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '英単語学習 - データバックアップ',
        text: '単語データのバックアップファイルです。このファイルを保存しておくことで、いつでもデータを復元できます。',
      );
    } catch (e) {
      debugPrint('エクスポートエラー: $e');
      rethrow;
    }
  }

  // JSONからデータをインポート
  Future<ImportResult> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final vocabularies = data['vocabularies'] as List<dynamic>;

      int importedCount = 0;
      int skippedCount = 0;
      int updatedCount = 0;

      for (var vocabData in vocabularies) {
        final id = vocabData['id'] as String;
        final existing = _vocabularyBox.get(id);

        if (existing == null) {
          // 新規追加
          final vocab = Vocabulary(
            id: id,
            english: vocabData['english'] as String,
            japanese: vocabData['japanese'] as String,
            createdAt: DateTime.parse(vocabData['createdAt'] as String),
            correctCount: vocabData['correctCount'] as int? ?? 0,
            wrongCount: vocabData['wrongCount'] as int? ?? 0,
          );
          await _vocabularyBox.put(id, vocab);
          importedCount++;
        } else {
          // 既存データの更新（統計を保持）
          existing.english = vocabData['english'] as String;
          existing.japanese = vocabData['japanese'] as String;
          // 既存の統計と比較して、大きい方を採用
          final importCorrect = vocabData['correctCount'] as int? ?? 0;
          final importWrong = vocabData['wrongCount'] as int? ?? 0;
          if (importCorrect > existing.correctCount ||
              importWrong > existing.wrongCount) {
            existing.correctCount = importCorrect;
            existing.wrongCount = importWrong;
            updatedCount++;
          } else {
            skippedCount++;
          }
          await existing.save();
        }
      }

      _loadVocabularies();

      return ImportResult(
        success: true,
        importedCount: importedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        totalCount: vocabularies.length,
      );
    } catch (e) {
      debugPrint('インポートエラー: $e');
      return ImportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ファイルからインポート
  Future<ImportResult> importFromFile() async {
    try {
      // ファイル選択
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          errorMessage: 'ファイルが選択されませんでした',
        );
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      return await importFromJson(jsonString);
    } catch (e) {
      debugPrint('ファイル読み込みエラー: $e');
      return ImportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// インポート結果を表すクラス
class ImportResult {
  final bool success;
  final int importedCount;
  final int updatedCount;
  final int skippedCount;
  final int totalCount;
  final String? errorMessage;

  ImportResult({
    required this.success,
    this.importedCount = 0,
    this.updatedCount = 0,
    this.skippedCount = 0,
    this.totalCount = 0,
    this.errorMessage,
  });
}
