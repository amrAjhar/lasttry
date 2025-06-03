import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'supabase_service.dart';
import 'custom_app_bar.dart';

class TextConversionPage extends StatefulWidget {
  const TextConversionPage({super.key});

  @override
  State<TextConversionPage> createState() => _TextConversionPageState();
}

class _TextConversionPageState extends State<TextConversionPage> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  String _convertedText = '';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processAndLogConversion({
    required String conversionTypeForDisplay,
    required String conversionTypeForLogging,
    required String Function() conversionLogic,
  }) async {
    if (_textController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce metin girin')),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    if (!mounted) return;

    final String originalText = _textController.text;
    final String newConvertedText = conversionLogic();

    if (mounted) {
      setState(() {
        _convertedText = newConvertedText;
        _isLoading = false;
      });
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null && originalText.isNotEmpty && newConvertedText.isNotEmpty) {
      try {
        await _supabaseService.addTextHistory(
          userId: currentUser.uid,
          originalText: originalText,
          convertedText: newConvertedText,
          conversionType: conversionTypeForLogging,
        );
        print('Conversion ($conversionTypeForLogging) logged to Supabase.');
      } catch (e) {
        print('Failed to log conversion to Supabase: $e');
      }
    }
  }

  String _convertToUppercase() => _textController.text.toUpperCase();
  String _convertToLowercase() => _textController.text.toLowerCase();
  String _reverseText() => _textController.text.split('').reversed.join();
  String _capitalizeWords() => _textController.text.split(' ').map((word) {
    if (word.isEmpty) return '';
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');

  Future<void> _copyToClipboard() async {
    if (_convertedText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kopyalanacak metin yok')),
        );
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: _convertedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panoya kopyalandı!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Metin Dönüştürücü',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Metin Girin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Metninizi buraya yazın...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _textController.clear();
                                if (mounted) setState(() => _convertedText = '');
                              },
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildConversionButton(
                      'BÜYÜK HARF', Icons.text_fields_sharp,
                          () => _processAndLogConversion(
                        conversionTypeForDisplay: 'BÜYÜK HARF',
                        conversionTypeForLogging: 'uppercase',
                        conversionLogic: _convertToUppercase,
                      ),
                    ),
                    _buildConversionButton(
                      'küçük harf', Icons.text_format_sharp,
                          () => _processAndLogConversion(
                        conversionTypeForDisplay: 'küçük harf',
                        conversionTypeForLogging: 'lowercase',
                        conversionLogic: _convertToLowercase,
                      ),
                    ),
                    _buildConversionButton(
                      'Ters Çevir', Icons.swap_horiz_sharp,
                          () => _processAndLogConversion(
                        conversionTypeForDisplay: 'Ters Çevir',
                        conversionTypeForLogging: 'reverse',
                        conversionLogic: _reverseText,
                      ),
                    ),
                    _buildConversionButton(
                      'Baş Harfler Büyük', Icons.text_rotate_vertical_sharp,
                          () => _processAndLogConversion(
                        conversionTypeForDisplay: 'Baş Harfler Büyük',
                        conversionTypeForLogging: 'capitalize_words',
                        conversionLogic: _capitalizeWords,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_convertedText.isNotEmpty && !_isLoading)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dönüştürülen Metin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.copy_all_outlined),
                                onPressed: _copyToClipboard,
                                tooltip: 'Panoya kopyala',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              _convertedText,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          ),
                        ],
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

  Widget _buildConversionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}