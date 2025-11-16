import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
}
