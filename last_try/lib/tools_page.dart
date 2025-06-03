import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_drawer.dart';
import 'custom_app_bar.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  int _wordCount = 0;
  int _charCount = 0;
  int _lineCount = 0;
  final _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _textController.addListener(_countWordsAndChars);
  }

  @override
  void dispose() {
    _textController.removeListener(_countWordsAndChars);
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _countWordsAndChars() {
    if (!mounted) return;

    String text = _textController.text;
    int newCharCount = text.length;
    int newLineCount = text.split('\n').length;

    int newWordCount;
    if (text.trim().isEmpty) {
      newWordCount = 0;
    } else {
      newWordCount = text.trim().split(RegExp(r'\s+')).length;
    }

    if (newCharCount != _charCount ||
        newWordCount != _wordCount ||
        newLineCount != _lineCount) {
      setState(() {
        _charCount = newCharCount;
        _wordCount = newWordCount;
        _lineCount = newLineCount;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak metin yok')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metin panoya kopyalandı')),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      setState(() {
        _textController.text = data.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Metin Araçları',
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Metin Girişi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.paste),
                                  onPressed: _pasteFromClipboard,
                                  tooltip: 'Panodan yapıştır',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: _copyToClipboard,
                                  tooltip: 'Panoya kopyala',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _textController.clear();
                                    setState(() {
                                      _wordCount = 0;
                                      _charCount = 0;
                                      _lineCount = 0;
                                    });
                                  },
                                  tooltip: 'Temizle',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Metninizi buraya yazın veya yapıştırın...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İstatistikler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Kelimeler', _wordCount),
                        const Divider(),
                        _buildStatRow('Karakterler', _charCount),
                        const Divider(),
                        _buildStatRow('Satırlar', _lineCount),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Not: Kelime sayımı boşluklara göre yapılır. Karakter sayımı boşluk ve satır sonlarını içerir.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}