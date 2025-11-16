import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocabulary_provider.dart';
import '../models/vocabulary.dart';
import 'dart:math';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isTestStarted = false;
  int _currentQuestionIndex = 0;
  List<Vocabulary> _testVocabularies = [];
  List<String> _choices = [];
  String? _selectedAnswer;
  bool _showAnswer = false;
  int _correctCount = 0;
  int _wrongCount = 0;

  void _startTest(int questionCount) {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    
    if (provider.vocabularies.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('テストを開始するには最低4つの単語が必要です'),
        ),
      );
      return;
    }

    setState(() {
      _isTestStarted = true;
      _currentQuestionIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      
      // テストする単語をランダムに選択
      _testVocabularies = provider.getRandomVocabularies(
        min(questionCount, provider.vocabularies.length),
      );
      
      _loadQuestion();
    });
  }

  void _loadQuestion() {
    if (_currentQuestionIndex >= _testVocabularies.length) {
      return;
    }

    final currentVocab = _testVocabularies[_currentQuestionIndex];
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    
    // 正解の選択肢
    final correctAnswer = currentVocab.japanese;
    
    // 不正解の選択肢を3つランダムに選ぶ
    final wrongChoices = provider.vocabularies
        .where((v) => v.id != currentVocab.id)
        .map((v) => v.japanese)
        .toList()
      ..shuffle();
    
    // 選択肢を作成（正解1つ + 不正解3つ）
    _choices = [
      correctAnswer,
      ...wrongChoices.take(3),
    ]..shuffle();
    
    setState(() {
      _selectedAnswer = null;
      _showAnswer = false;
    });
  }

  void _checkAnswer(String answer) {
    if (_showAnswer) return;

    final currentVocab = _testVocabularies[_currentQuestionIndex];
    final isCorrect = answer == currentVocab.japanese;
    
    setState(() {
      _selectedAnswer = answer;
      _showAnswer = true;
      
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    // 統計を更新
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    provider.updateStats(currentVocab.id, isCorrect);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _testVocabularies.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _loadQuestion();
      });
    } else {
      // テスト終了
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('テスト結果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _correctCount >= _testVocabularies.length * 0.7
                  ? Icons.emoji_events
                  : Icons.thumb_up,
              size: 64,
              color: _correctCount >= _testVocabularies.length * 0.7
                  ? Colors.amber
                  : Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '正解: $_correctCount / ${_testVocabularies.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '正答率: ${((_correctCount / _testVocabularies.length) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isTestStarted = false;
              });
            },
            child: const Text('終了'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startTest(_testVocabularies.length);
            },
            child: const Text('もう一度'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.purple,
                    Colors.deepPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.deepPurple,
                ],
              ).createShader(bounds),
              child: const Text(
                '英単語テスト',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: _isTestStarted
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '${_currentQuestionIndex + 1} / ${_testVocabularies.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _isTestStarted ? _buildTestView() : _buildStartView(),
    );
  }

  Widget _buildStartView() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, child) {
        if (provider.vocabularies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'テストを始めるには',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '単語帳に単語を追加してください',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '英単語テスト',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '登録されている単語: ${provider.vocabularies.length}個',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '問題数を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTestOption(
              title: '5問',
              subtitle: 'サクッとテスト',
              icon: Icons.speed,
              onTap: () => _startTest(5),
              enabled: provider.vocabularies.length >= 4,
            ),
            _buildTestOption(
              title: '10問',
              subtitle: '標準テスト',
              icon: Icons.edit_note,
              onTap: () => _startTest(10),
              enabled: provider.vocabularies.length >= 4,
            ),
            _buildTestOption(
              title: '20問',
              subtitle: 'しっかりテスト',
              icon: Icons.assignment,
              onTap: () => _startTest(20),
              enabled: provider.vocabularies.length >= 4,
            ),
            _buildTestOption(
              title: '全問',
              subtitle: '全ての単語でテスト',
              icon: Icons.done_all,
              onTap: () => _startTest(provider.vocabularies.length),
              enabled: provider.vocabularies.length >= 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: enabled ? null : Colors.grey[400],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled ? null : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestView() {
    final currentVocab = _testVocabularies[_currentQuestionIndex];

    return Column(
      children: [
        // 進捗バー
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _testVocabularies.length,
          backgroundColor: Colors.grey[200],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // スコア表示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoreChip(
                    icon: Icons.check_circle,
                    count: _correctCount,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildScoreChip(
                    icon: Icons.cancel,
                    count: _wrongCount,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 問題カード
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '次の英単語の意味は？',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentVocab.english,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 選択肢
              ..._choices.map((choice) {
                final isSelected = _selectedAnswer == choice;
                final isCorrect = choice == currentVocab.japanese;
                final showCorrect = _showAnswer && isCorrect;
                final showWrong = _showAnswer && isSelected && !isCorrect;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: showCorrect
                      ? Colors.green[50]
                      : showWrong
                          ? Colors.red[50]
                          : null,
                  child: InkWell(
                    onTap: () => _checkAnswer(choice),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (showCorrect)
                            Icon(Icons.check_circle, color: Colors.green[700])
                          else if (showWrong)
                            Icon(Icons.cancel, color: Colors.red[700])
                          else
                            Icon(Icons.radio_button_unchecked,
                                color: Colors.grey[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              choice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: showCorrect
                                    ? Colors.green[700]
                                    : showWrong
                                        ? Colors.red[700]
                                        : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_showAnswer) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _nextQuestion,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(
                    _currentQuestionIndex < _testVocabularies.length - 1
                        ? '次の問題へ'
                        : '結果を見る',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
