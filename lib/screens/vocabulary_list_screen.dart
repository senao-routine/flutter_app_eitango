import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocabulary_provider.dart';
import '../models/vocabulary.dart';
import 'add_edit_vocabulary_screen.dart';

enum AccuracyFilter {
  all,
  weak,
  normal,
  strong,
}

class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AccuracyFilter _accuracyFilter = AccuracyFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Vocabulary> _filterVocabularies(List<Vocabulary> vocabularies) {
    var filtered = vocabularies;

    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vocab) {
        final query = _searchQuery.toLowerCase();
        return vocab.english.toLowerCase().contains(query) ||
            vocab.japanese.toLowerCase().contains(query);
      }).toList();
    }

    // 正答率フィルター
    switch (_accuracyFilter) {
      case AccuracyFilter.weak:
        filtered = filtered.where((vocab) {
          final total = vocab.correctCount + vocab.wrongCount;
          return total > 0 && vocab.accuracy < 40;
        }).toList();
        break;
      case AccuracyFilter.normal:
        filtered = filtered.where((vocab) {
          final total = vocab.correctCount + vocab.wrongCount;
          return total > 0 && vocab.accuracy >= 40 && vocab.accuracy < 70;
        }).toList();
        break;
      case AccuracyFilter.strong:
        filtered = filtered.where((vocab) {
          final total = vocab.correctCount + vocab.wrongCount;
          return total > 0 && vocab.accuracy >= 70;
        }).toList();
        break;
      case AccuracyFilter.all:
        break;
    }

    return filtered;
  }

  Future<void> _exportData() async {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);

    if (provider.vocabularies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エクスポートする単語がありません')),
      );
      return;
    }

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await provider.exportAndShare();

      if (mounted) {
        Navigator.pop(context); // ローディング閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.vocabularies.length}個の単語をエクスポートしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ローディング閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);

    // 確認ダイアログ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをインポート'),
        content: const Text(
          'バックアップファイルから単語データをインポートします。\n\n'
          '既存の単語と重複する場合は、より高い統計データが保持されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ファイルを選択'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await provider.importFromFile();

      if (mounted) {
        Navigator.pop(context); // ローディング閉じる

        if (result.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('インポート完了'),
              content: Text(
                '新規追加: ${result.importedCount}個\n'
                '更新: ${result.updatedCount}個\n'
                'スキップ: ${result.skippedCount}個\n'
                '合計: ${result.totalCount}個',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('インポートに失敗しました: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ローディング閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使い方'),
        content: const Text(
          '• 検索バーで単語を検索\n'
          '• フィルターアイコンで正答率別に表示\n'
          '• 右下の「+」ボタンで新しい単語を追加\n'
          '• 単語カードをタップして編集\n'
          '• 左にスワイプして削除\n'
          '• 「テスト」タブでテストを開始\n\n'
          '【データバックアップ】\n'
          '• メニュー > エクスポートでバックアップ作成\n'
          '• メニュー > インポートで復元',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('正答率でフィルター'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AccuracyFilter>(
                  title: const Text('全て表示'),
                  value: AccuracyFilter.all,
                  groupValue: _accuracyFilter,
                  onChanged: (value) {
                    setDialogState(() {
                      _accuracyFilter = value!;
                    });
                  },
                ),
                RadioListTile<AccuracyFilter>(
                  title: Row(
                    children: [
                      const Text('苦手な単語'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '< 40%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: AccuracyFilter.weak,
                  groupValue: _accuracyFilter,
                  onChanged: (value) {
                    setDialogState(() {
                      _accuracyFilter = value!;
                    });
                  },
                ),
                RadioListTile<AccuracyFilter>(
                  title: Row(
                    children: [
                      const Text('普通の単語'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '40-70%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: AccuracyFilter.normal,
                  groupValue: _accuracyFilter,
                  onChanged: (value) {
                    setDialogState(() {
                      _accuracyFilter = value!;
                    });
                  },
                ),
                RadioListTile<AccuracyFilter>(
                  title: Row(
                    children: [
                      const Text('得意な単語'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '≥ 70%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: AccuracyFilter.strong,
                  groupValue: _accuracyFilter,
                  onChanged: (value) {
                    setDialogState(() {
                      _accuracyFilter = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('適用'),
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
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: const Text(
                '単語帳',
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
        actions: [
          IconButton(
            icon: Icon(
              _accuracyFilter != AccuracyFilter.all
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterDialog,
            tooltip: '正答率でフィルター',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'import':
                  _importData();
                  break;
                case 'info':
                  _showInfoDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 12),
                    Text('データをエクスポート'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 12),
                    Text('データをインポート'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('使い方'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, child) {
          if (provider.vocabularies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '単語がまだ登録されていません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右下の「+」ボタンから追加してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredVocabularies = _filterVocabularies(provider.vocabularies);

          return Column(
            children: [
              // 検索バー
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '英単語または日本語訳で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // フィルター状態表示
              if (_accuracyFilter != AccuracyFilter.all)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _accuracyFilter == AccuracyFilter.weak
                              ? '苦手な単語を表示中 (正答率 < 40%)'
                              : _accuracyFilter == AccuracyFilter.normal
                                  ? '普通の単語を表示中 (正答率 40-70%)'
                                  : '得意な単語を表示中 (正答率 ≥ 70%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _accuracyFilter = AccuracyFilter.all;
                          });
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              if (_accuracyFilter != AccuracyFilter.all)
                const SizedBox(height: 8),
              // 結果表示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredVocabularies.length}件',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty ||
                        _accuracyFilter != AccuracyFilter.all)
                      Text(
                        ' / ${provider.vocabularies.length}件',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 単語リスト
              Expanded(
                child: filteredVocabularies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '該当する単語が見つかりません',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _accuracyFilter != AccuracyFilter.all) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _accuracyFilter = AccuracyFilter.all;
                                  });
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('フィルターをクリア'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredVocabularies.length,
                        itemBuilder: (context, index) {
                          final vocab = filteredVocabularies[index];
                          return _VocabularyCard(
                            vocabulary: vocab,
                            searchQuery: _searchQuery,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditVocabularyScreen(
                                    vocabulary: vocab,
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('削除確認'),
                                  content: Text('「${vocab.english}」を削除しますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        '削除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                provider.deleteVocabulary(vocab.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('単語を削除しました')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditVocabularyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VocabularyCard({
    required this.vocabulary,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final matches = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    var lastMatchEnd = 0;

    while (lastMatchEnd < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, lastMatchEnd);
      if (matchIndex == -1) {
        matches.add(TextSpan(text: text.substring(lastMatchEnd)));
        break;
      }

      if (matchIndex > lastMatchEnd) {
        matches.add(TextSpan(text: text.substring(lastMatchEnd, matchIndex)));
      }

      matches.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastMatchEnd = matchIndex + query.length;
    }

    return TextSpan(children: matches);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(vocabulary.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('削除確認'),
            content: Text('「${vocabulary.english}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '削除',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            _buildHighlightedText(
                              vocabulary.english,
                              searchQuery,
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (vocabulary.correctCount + vocabulary.wrongCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: vocabulary.accuracy >= 70
                              ? Colors.green.withValues(alpha: 0.1)
                              : vocabulary.accuracy >= 40
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${vocabulary.accuracy.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: vocabulary.accuracy >= 70
                                ? Colors.green[700]
                                : vocabulary.accuracy >= 40
                                    ? Colors.orange[700]
                                    : Colors.red[700],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      _buildHighlightedText(
                        vocabulary.japanese,
                        searchQuery,
                      ),
                    ],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (vocabulary.correctCount + vocabulary.wrongCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vocabulary.correctCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vocabulary.wrongCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
