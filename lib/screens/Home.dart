import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _speechErrorOccurred = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  final TextEditingController _amountController = TextEditingController();
  List<String> _coinCombo = [];
  List<String> _originalCombo = [];

  late AnimationController _micRippleController;
  late Animation<double> _rippleValue;
  OverlayEntry? _errorOverlay;
  AnimationController? _errorController;
  Timer? _errorTimer;

  static const Map<String, String> _numberWords = {
    'zero': '0',
    'oh': '0',
    'o': '0',
    'one': '1',
    'won': '1',
    'two': '2',
    'to': '2',
    'too': '2',
    'three': '3',
    'tree': '3',
    'four': '4',
    'for': '4',
    'fore': '4',
    'five': '5',
    'hive': '5',
    'six': '6',
    'sex': '6',
    'seven': '7',
    'eight': '8',
    'ate': '8',
    'nine': '9',
    'nein': '9',
    'ten': '10',
    'eleven': '11',
    'twelve': '12',
    'thirteen': '13',
    'fourteen': '14',
    'fifteen': '15',
    'sixteen': '16',
    'seventeen': '17',
    'eighteen': '18',
    'nineteen': '19',
    'twenty': '20',
    'thirty': '30',
    'forty': '40',
    'fifty': '50',
    'sixty': '60',
    'seventy': '70',
    'eighty': '80',
    'ninety': '90',
    'hundred': '100',
    'point': '.',
    'dot': '.',
    'decimal': '.',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimations();
  }

  void _initAnimations() {
    _micRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rippleValue = CurvedAnimation(
      parent: _micRippleController,
      curve: Curves.easeOut,
    );

    _micRippleController.addStatusListener((status) {
      if (_isListening && status == AnimationStatus.completed) {
        _micRippleController.forward(from: 0.0);
      }
    });
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );
      setState(() {});
    } catch (e) {
      _showError("Speech initialization failed");
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;

    setState(() {
      if (status == 'listening') {
        _micRippleController.forward(from: 0.0);
        _isListening = true;
        _speechErrorOccurred = false;
      } else if (status == 'done') {
        _isListening = false;
        if (_wordsSpoken == "Listening...") {
          _wordsSpoken = "";
        }
      }
    });
  }

  void _handleSpeechError(error) {
    if (_speechErrorOccurred) return;

    _speechErrorOccurred = true;
    _stopListening();
    _showError("Speech recognition error. Try again.");
  }

  Future<void> _toggleListening() async {
    if (_speechErrorOccurred) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _initSpeech();
      if (!mounted) return;
      setState(() {
        _speechErrorOccurred = false;
      });
    }

    if (!_speechToText.isListening) {
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  Future<void> _startListening() async {
    try {
      _micRippleController.forward(from: 0.0);
      if (!mounted) return;
      setState(() {
        _isListening = true;
        _wordsSpoken = "Listening...";
      });

      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('speechLanguage') ?? 'en';

      await _speechToText.listen(
        listenMode: ListenMode.dictation,
        onResult: _onSpeechResult,
        cancelOnError: true,
        partialResults: true,
        localeId: language,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (_) {},
      );
    } catch (e) {
      _handleSpeechError(e);
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    } catch (e) {
      // Ignore stop errors
    }
  }

  void _onSpeechResult(result) {
    if (!mounted) return;

    final text = result.recognizedWords.trim();
    final isFinal = result.finalResult;
    final hasContent = text.isNotEmpty;

    setState(() {
      _wordsSpoken = text;
      _confidenceLevel = result.confidence;
    });

    if (hasContent && (isFinal || result.confidence > 0.5)) {
      final extracted = _extractAmount(text);
      if (extracted.isEmpty) {
        if (isFinal) {
          _showError("Couldn't detect a valid amount");
        }
      } else {
        _validateAndProcessAmount(extracted);
      }
    }
  }

  String _extractAmount(String text) {
    // First try direct number matching (digits or decimal numbers)
    final digitMatch = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    if (digitMatch != null) return digitMatch.group(1)!;

    // Then try word conversion
    final buffer = StringBuffer();
    final words = text.toLowerCase().split(
      RegExp(r'[^a-zA-Z0-9.]'),
    ); // Split on non-alphanumeric

    bool foundNumber = false;

    for (final word in words.where((w) => w.isNotEmpty)) {
      if (_numberWords.containsKey(word)) {
        buffer.write(_numberWords[word]);
        foundNumber = true;
      } else if (word == 'and') {
        continue;
      } else if (word == 'euro' || word == 'euros') {
        // Ignore currency words
        continue;
      } else if (foundNumber) {
        // If we already found a number, stop processing
        break;
      }
    }

    // If we found any number words, return the result
    if (foundNumber) {
      return buffer.toString();
    }

    // Try to match single word numbers (like "nine")
    final singleWordMatch = _numberWords.keys.firstWhere(
      (key) => text.toLowerCase().contains(key),
      orElse: () => '',
    );

    if (singleWordMatch.isNotEmpty) {
      return _numberWords[singleWordMatch]!;
    }

    return '';
  }

  void _validateAndProcessAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) {
      _showError("Invalid amount");
      return;
    }

    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      _showError("Amount must be > 0");
      return;
    }

    if (amount > 100) {
      _showError("Max amount is €100");
      return;
    }

    _amountController.text = amount.toStringAsFixed(2);
    _calculateCoins(amount);
  }

  void _calculateCoins(double amount) {
    final coins = [
      MapEntry("two_euro", 2.0),
      MapEntry("one_euro", 1.0),
      MapEntry("fifty_cent", 0.5),
      MapEntry("twenty_cent", 0.2),
      MapEntry("ten_cent", 0.1),
      MapEntry("five_cent", 0.05),
      MapEntry("two_cent", 0.02),
      MapEntry("one_cent", 0.01),
    ];

    double remaining = amount;
    final result = <String>[];

    for (final coin in coins) {
      while (remaining >= coin.value) {
        result.add(coin.key);
        remaining = (remaining - coin.value).toPrecision(2);
      }
    }

    if (remaining > 0.009) {
      result.add("one_cent");
    }

    setState(() {
      _coinCombo = List.from(result);
      _originalCombo = List.from(result);
    });
  }

  void _downgradeCoinType(int index) {
    const downgradeMap = {
      "two_euro": ["one_euro", "one_euro"],
      "one_euro": ["fifty_cent", "fifty_cent"],
      "fifty_cent": ["twenty_cent", "twenty_cent", "ten_cent"],
      "twenty_cent": ["ten_cent", "ten_cent"],
      "ten_cent": ["five_cent", "five_cent"],
      "five_cent": ["two_cent", "two_cent", "one_cent"],
      "two_cent": ["one_cent", "one_cent"],
    };

    final coinType = _coinCombo[index];
    if (downgradeMap.containsKey(coinType)) {
      setState(() {
        final updatedCombo = List.of(_coinCombo);
        updatedCombo.replaceRange(index, index + 1, downgradeMap[coinType]!);
        _coinCombo = updatedCombo;
      });
    }
  }

  bool _isOriginalCombo() {
    if (_coinCombo.length != _originalCombo.length) return false;
    for (int i = 0; i < _coinCombo.length; i++) {
      if (_coinCombo[i] != _originalCombo[i]) return false;
    }
    return true;
  }

  void _resetCombo() {
    setState(() {
      if (_isOriginalCombo() || _originalCombo.isEmpty) {
        _amountController.clear();
        _coinCombo.clear();
        _originalCombo.clear();
      } else {
        _coinCombo = List.of(_originalCombo);
      }
    });
  }

  void _showError(String message) {
    _removeErrorPopup();

    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _errorOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _errorController!,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _errorController!,
                    curve: Curves.easeOut,
                  ),
                ),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_errorOverlay!);
    _errorController!.forward();

    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _errorController?.reverse().then((_) => _removeErrorPopup());
      }
    });
  }

  void _removeErrorPopup() {
    _errorTimer?.cancel();
    _errorController?.dispose();
    _errorOverlay?.remove();
    _errorController = null;
    _errorOverlay = null;
  }

  @override
  void dispose() {
    _micRippleController.dispose();
    _amountController.dispose();
    _removeErrorPopup();
    _errorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (_wordsSpoken.isNotEmpty && _wordsSpoken != "Listening...")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recognized: "$_wordsSpoken" (${(_confidenceLevel * 100).toStringAsFixed(1)}% confidence)',
                  style: TextStyle(
                    color:
                        _confidenceLevel > 0.7
                            ? Colors.green
                            : _confidenceLevel > 0.5
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rippleValue,
                      builder: (context, child) {
                        final scale = 1 + (_rippleValue.value * 1.6);
                        return Opacity(
                          opacity: 1 - _rippleValue.value,
                          child: Container(
                            width: 190 * scale,
                            height: 190 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                    Material(
                      color: Colors.redAccent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _toggleListening,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white24,
                        child: const Padding(
                          padding: EdgeInsets.all(60),
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter amount (€0.01 - €100)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _validateAndProcessAmount,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  itemCount: _coinCombo.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _downgradeCoinType(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/coins/${_coinCombo[index]}.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetCombo,
                  icon: const Icon(Icons.refresh),
                  label: Text(_isOriginalCombo() ? "Clear" : "Reset"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[850],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

extension DoublePrecision on double {
  double toPrecision(int fractionDigits) =>
      double.parse(toStringAsFixed(fractionDigits));
}
