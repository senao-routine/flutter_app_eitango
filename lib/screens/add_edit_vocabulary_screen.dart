import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';

class AddEditVocabularyScreen extends StatefulWidget {
  final Vocabulary? vocabulary;

  const AddEditVocabularyScreen({
    super.key,
    this.vocabulary,
  });

  @override
  State<AddEditVocabularyScreen> createState() =>
      _AddEditVocabularyScreenState();
}

class _AddEditVocabularyScreenState extends State<AddEditVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _englishController;
  late TextEditingController _japaneseController;

  @override
  void initState() {
    super.initState();
    _englishController = TextEditingController(
      text: widget.vocabulary?.english ?? '',
    );
    _japaneseController = TextEditingController(
      text: widget.vocabulary?.japanese ?? '',
    );
  }

  @override
  void dispose() {
    _englishController.dispose();
    _japaneseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<VocabularyProvider>(context, listen: false);

    if (widget.vocabulary == null) {
      // 新規追加
      await provider.addVocabulary(
        _englishController.text.trim(),
        _japaneseController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('単語を追加しました')),
        );
      }
    } else {
      // 編集
      await provider.updateVocabulary(
        widget.vocabulary!.id,
        _englishController.text.trim(),
        _japaneseController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('単語を更新しました')),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vocabulary != null;

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
                  colors: isEditing
                      ? [Colors.orange, Colors.deepOrange]
                      : [Colors.green, Colors.teal],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isEditing ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isEditing ? Icons.edit_rounded : Icons.add_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isEditing
                    ? [Colors.orange, Colors.deepOrange]
                    : [Colors.green, Colors.teal],
              ).createShader(bounds),
              child: Text(
                isEditing ? '単語を編集' : '単語を追加',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '英単語',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _englishController,
                      decoration: const InputDecoration(
                        hintText: '例: apple',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.translate),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '英単語を入力してください';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '日本語訳',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _japaneseController,
                      decoration: const InputDecoration(
                        hintText: '例: りんご',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '日本語訳を入力してください';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? '保存する' : '追加する'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
