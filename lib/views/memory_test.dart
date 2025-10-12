import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryTestPage extends StatefulWidget {
  final String studentId;
  const MemoryTestPage({super.key, required this.studentId});

  @override
  State<MemoryTestPage> createState() => _MemoryTestPageState();
}

class _MemoryTestPageState extends State<MemoryTestPage> {
  final Random _random = Random();

  // Game session variables
  List<int> _gameOrder = [];
  int _currentGameIndex = 0;
  int _score = 0;
  bool _gameScored = false;

  bool _gameOver = false;
  Timer? _gameTimer;
  int _timeLeft = 10;

  // Game-specific states
  List<int> _sequence = [];
  List<int> _userSequence = [];
  bool _showSequence = true;
  int? _reactionStart;
  bool _signalShown = false;

  // List<String> _words = ["Cat", "Tree", "Book", "Moon", "Car", "Sun", "Dog"];
  // List<String> _shownWords = [];
  List<String> _userWords = [];

  int? _patternHighlight;

  // -------------------- START TEST --------------------
  void _startTest() async {
    _score = 0;
    _gameOver = false;

    final prefs = await SharedPreferences.getInstance();
    List<String>? lastOrder = prefs.getStringList('lastGameOrder');

    // Create new shuffled order
    List<int> newOrder = List.generate(10, (i) => i)..shuffle();
    while (lastOrder != null &&
        listEquals(lastOrder.map(int.parse).toList(), newOrder)) {
      newOrder.shuffle();
    }

    prefs.setStringList(
        'lastGameOrder', newOrder.map((e) => e.toString()).toList());

    setState(() {
      _gameOrder = newOrder;
      _currentGameIndex = 0;
    });

    _startGameTimer();
  }

  // -------------------- GAME TIMER --------------------
  void _startGameTimer() {
    _timeLeft = 10;
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _nextGame();
      }
    });
  }

  void _nextGame({bool scored = false}) {
    if (!mounted) return; // Add mounted check
    
    if (scored) _score = (_score + 1).clamp(0, 10);

    _gameTimer?.cancel();
    _resetGameStates();

    if (_currentGameIndex < 9) {
      setState(() {
        _currentGameIndex++;
      });
      _startGameTimer();
    } else {
      _endTest();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }


  void _resetGameStates() {
  _sequence = [];
  _userSequence = [];
  _showSequence = true;
  _reactionSignal = false;
  _reactionStart = null;
  _patternSquare = null;
  _missingIndex = null;
  _numberSequence = null;
  _nextNumber = 1;
  _shownWords = [];
  _userWords = [];
}


  Future<void> _endTest() async {
    _gameTimer?.cancel();
    setState(() => _gameOver = true);

    final url = Uri.parse("$apiBaseUrl/focus-test/add");
    final body = jsonEncode({
      "studentId": widget.studentId,
      "score": _score,
      "date": DateTime.now().toIso8601String(),
    });

    try {
      await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
    } catch (e) {
      debugPrint("Error sending score: $e");
    }
  }

  // -------------------- SCREEN BUILDERS --------------------
  Widget _buildGameOverScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThemeHelpers.themedAvatar(
          size: 100,
          icon: Icons.celebration,
          gradient: LinearGradient(
            colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Test Completed!",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                "Your Score",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$_score / 10",
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ThemeHelpers.themedButton(
          text: "Back to Dashboard",
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 247, 183, 54),
            foregroundColor: AppTheme.textOnPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThemeHelpers.themedAvatar(
          size: 120,
          icon: Icons.psychology_outlined,
        ),
        const SizedBox(height: 24),
        Text(
          "Memory & Focus Test",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Ready to challenge your mind?",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Complete 10 different cognitive games to test your memory and focus abilities.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ThemeHelpers.themedButton(
          text: "Start Test",
          onPressed: _startTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 247, 183, 54),
            foregroundColor: AppTheme.textOnPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Game progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Game ${_currentGameIndex + 1} of 10",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Timer
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _timeLeft / 10,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                color: AppTheme.primaryColor,
                strokeWidth: 6,
              ),
              Text(
                "${_timeLeft}s",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Game content
        _buildGame(_gameOrder[_currentGameIndex]),
      ],
    );
  }

  // -------------------- GAME BUILDER --------------------
  Widget _buildGame(int index) {
    switch (index) {
      case 0:
        return _sequenceMemoryGame();
      case 1:
        return _quickMathGame();
      case 2:
        return _stroopGame();
      case 3:
        return _reactionGame();
      case 4:
        return _oddOneOutGame();
      case 5:
        return _wordRecallGame();
      case 6:
        return _patternMemoryGame();
      case 7:
        return _missingTileGame();
      case 8:
        return _numberTapGame();
      case 9:
        return _wordColorMatchGame();
      default:
        return const Text("Unknown Game");
    }
  }

  // -------------------- GAME 1: Sequence Memory --------------------
  Widget _sequenceMemoryGame() {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
    if (_sequence.isEmpty) {
      _sequence = List.generate(3 + _random.nextInt(3), (_) => _random.nextInt(4));
      _showSequence = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showSequence = false;
          setState(() {});
        }
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Sequence Memory",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Repeat the sequence of colors displayed!",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _showSequence
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _sequence
                    .map((i) => Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors[i],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors[i].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(4, (i) {
                  return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors[i],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        _userSequence.add(i);
                        if (_userSequence.length == _sequence.length) {
                          if (listEquals(_userSequence, _sequence)) _score++;
                          _nextGame();
                        }
                      },
                      child: const SizedBox());
                }),
              ),
      ],
    );
  }

  // -------------------- GAME 2: Quick Math --------------------
  int? _mathA;
int? _mathB;
int? _mathAnswer;
List<int>? _mathOptions;

Widget _quickMathGame() {
  if (_mathA == null) {
    _mathA = _random.nextInt(10);
    _mathB = _random.nextInt(10);
    _mathAnswer = _mathA! + _mathB!;
    _mathOptions = [_mathAnswer!, _mathAnswer! + 1, _mathAnswer! - 1, _mathAnswer! + 2]..shuffle();
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Quick Math",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Solve this problem quickly!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          "$_mathA + $_mathB = ?",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _mathOptions!.map((o) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 247, 183, 54),
              foregroundColor: AppTheme.textOnPrimary,
              minimumSize: const Size(60, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: () {
              if (o == _mathAnswer) _score++;
              _mathA = null;
              _mathB = null;
              _mathAnswer = null;
              _mathOptions = null;
              _nextGame();
            },
            child: Text(
              "$o",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      )
    ],
  );
}


  // -------------------- GAME 3: Stroop --------------------
  Widget _stroopGame() {
    final colorMap = {"Red": Colors.red, "Green": Colors.green, "Blue": Colors.blue, "Orange": Colors.orange};
    List<String> words = colorMap.keys.toList();
    int wordIndex = _random.nextInt(4);
    int colorIndex = _random.nextInt(4);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Stroop Test",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tap the color of the text, not the word!",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            words[wordIndex],
            style: GoogleFonts.poppins(
              color: colorMap[words[colorIndex]],
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: colorMap.keys.map((c) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 247, 183, 54),
                foregroundColor: AppTheme.textOnPrimary,
                minimumSize: const Size(80, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () {
                if (c == words[colorIndex]) _score++;
                _nextGame();
              },
              child: Text(
                c,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  // -------------------- GAME 4: Reaction Speed --------------------
  bool _reactionSignal = false;


Widget _reactionGame() {
  if (!_reactionSignal) {
    Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
      if (mounted) {
        setState(() {
          _reactionSignal = true;
          _reactionStart = DateTime.now().millisecondsSinceEpoch;
        });
      }
    });
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Reaction Test",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap the button as soon as you see GO!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      Container(
        width: 200,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _reactionSignal
                ? [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)]
                : [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _reactionSignal ? AppTheme.successColor : AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _reactionSignal
              ? () {
                  if (_reactionStart != null) {
                    int reactionTime =
                        DateTime.now().millisecondsSinceEpoch - _reactionStart!;
                    if (reactionTime < 1000) _score++; // fast reaction
                  }
                  _reactionSignal = false;
                  _reactionStart = null;
                  _nextGame();
                }
              : null,
          child: Text(
            _reactionSignal ? "GO!" : "Wait...",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _reactionSignal ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    ],
  );
}


  // -------------------- GAME 5: Odd One Out --------------------
Widget _oddOneOutGame() {
  int oddIndex = _random.nextInt(9);
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Odd One Out",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap the square that looks different!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(9, (i) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: i == oddIndex ? Colors.red : Colors.blue,
                minimumSize: const Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),),
            onPressed: () {
              if (i == oddIndex) _score++;
              _nextGame();
            },
            child: const SizedBox(),
          );
        }),
      ),
    ],
  );
}


  // -------------------- GAME 6: Word Recall --------------------
List<String> _words = ["Cat", "Tree", "Book", "Moon", "Car", "Sun", "Dog"];
List<String> _shownWords = [];
List<String> _options = [];
bool _showWords = true;

Widget _wordRecallGame() {
  // Initialize words to remember
  if (_shownWords.isEmpty) {
    _shownWords = (_words..shuffle()).take(5).toList();
    _showWords = true;

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showWords = false;

        // Include at least one correct word
        List<String> wrongWords = _words
            .where((w) => !_shownWords.contains(w))
            .toList()
              ..shuffle();

        // Mix 1 correct + 3 wrong words
        _options = (_shownWords.take(1).toList() + wrongWords.take(3).toList())..shuffle();
      });
    });
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Word Recall",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _showWords ? "Remember these words!" : "Select a word you remember from the list:",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),

      // Show words to remember
      if (_showWords)
        Wrap(
          spacing: 8,
          children: _shownWords
              .map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.secondaryColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      w,
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
        ),

      // Show options after words disappear
      if (!_showWords)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _options
              .map((word) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 247, 183, 54),
                      foregroundColor: AppTheme.textOnPrimary,
                      minimumSize: const Size(80, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      // Award 1 point if the user selects a correct word
                      if (_shownWords.contains(word)) _score++;
                      
                      // Reset and move to next game
                      _shownWords = [];
                      _options = [];
                      _nextGame();
                    },
                    child: Text(
                      word,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
        ),
    ],
  );
}





  // -------------------- GAME 7: Pattern Memory --------------------
  int? _patternSquare;

Widget _patternMemoryGame() {
  if (_patternSquare == null) _patternSquare = _random.nextInt(9);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Pattern Memory",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap the highlighted square!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(9, (i) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: i == _patternSquare ? Colors.green : Colors.grey,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (i == _patternSquare) _score++;
              _patternSquare = null;
              _nextGame();
            },
            child: const SizedBox(),
          );
        }),
      ),
    ],
  );
}

  // -------------------- GAME 8: Missing Tile --------------------
 int? _missingIndex;

Widget _missingTileGame() {
  if (_missingIndex == null) _missingIndex = _random.nextInt(9);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Missing Tile",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap the blank spot!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(9, (i) {
          if (i == _missingIndex) {
            return GestureDetector(
              onTap: () {
                _score++;
                _missingIndex = null;
                _nextGame();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
              ),
            );
          } else {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }
        }),
      ),
    ],
  );
}



  // -------------------- GAME 9: Number Tap --------------------
List<int>? _numberSequence;
int _nextNumber = 1;
int _tappedCount = 0;
bool _numberGameAnswered = false;

Widget _numberTapGame() {
  if (_numberSequence == null) {
    _numberSequence = List.generate(5, (i) => i + 1)..shuffle(); // 5 numbers only
    _nextNumber = 1;
    _tappedCount = 0;
    _numberGameAnswered = false;
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Number Tap",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap numbers in ascending order!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _numberSequence!.map((n) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 247, 183, 54),
              foregroundColor: AppTheme.textOnPrimary,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _numberGameAnswered
                ? null
                : () {
                    if (!mounted) return; // mounted check

                    if (n == _nextNumber) {
                      _tappedCount++;
                      _nextNumber++; // move to next number
                    } else {
                      _numberGameAnswered = true; // wrong tap ends game
                    }

                    // Check if game finished
                    if (_tappedCount == _numberSequence!.length) {
                      // all numbers correct
                      _numberGameAnswered = true;
                      _score++;
                      _numberSequence = null;
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        _nextGame();
                      });
                    } else if (_numberGameAnswered) {
                      // wrong tap ends game without point
                      _numberSequence = null;
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        _nextGame();
                      });
                    }

                    setState(() {});
                  },
            child: Text(
              "$n",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}





  // -------------------- GAME 10: Word-Color Match --------------------
  Widget _wordColorMatchGame() {
  final words = ["Sun", "Sky", "Leaf", "Fire"];
  final colors = [Colors.yellow, Colors.blue, Colors.green, Colors.red];
  int correct = _random.nextInt(4);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Word-Color Match",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Tap the word that matches the color!",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          words[correct],
          style: GoogleFonts.poppins(
            color: colors[correct],
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(4, (i) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 247, 183, 54),
              foregroundColor: AppTheme.textOnPrimary,
              minimumSize: const Size(80, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: () {
              if (i == correct) _score++;
              _nextGame();
            },
            child: Text(
              words[i],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      )
    ],
  );
}

  // -------------------- OTHER GAMES --------------------
  // For brevity: Odd One Out, Word Recall, Pattern Memory, Missing Tile, Number Tap, Word-Color Match
  // You can replicate same pattern: short instruction + interactive buttons/grid

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemeHelpers.dashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header section with themed avatar and title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textOnPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ThemeHelpers.themedAvatar(
                      size: 50,
                      icon: Icons.psychology_outlined, // Memory/brain icon
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Memory & Focus Test',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: _gameOver
                          ? _buildGameOverScreen()
                          : (_gameOrder.isEmpty
                              ? _buildStartScreen()
                              : _buildGameScreen()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
