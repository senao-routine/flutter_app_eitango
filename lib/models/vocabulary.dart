import 'package:hive/hive.dart';

part 'vocabulary.g.dart';

@HiveType(typeId: 0)
class Vocabulary extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String english;

  @HiveField(2)
  late String japanese;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  int correctCount;

  @HiveField(5)
  int wrongCount;

  Vocabulary({
    required this.id,
    required this.english,
    required this.japanese,
    required this.createdAt,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  // 正答率を計算
  double get accuracy {
    final total = correctCount + wrongCount;
    if (total == 0) return 0.0;
    return (correctCount / total) * 100;
  }
}
