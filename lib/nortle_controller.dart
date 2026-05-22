import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'constants.dart';

class NortleController extends ChangeNotifier {
  late SharedPreferences _prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: 'https://nortle-default-rtdb.europe-west1.firebasedatabase.app')
      .ref('messages');

  GameMode _gameMode = GameMode.words;
  String _targetValue = "";
  int _mathTarget = 0;
  final List<String> _guesses = [];
  String _currentGuess = "";
  GameState _gameState = GameState.playing;
  String? _errorMessage;
  int _shakeTrigger = 0;
  bool _showConfetti = false;

  List<int> _countdownNumbers = [];
  int _largeNumbersSelected = 0;

  String _username = "";
  bool _isLoggedIn = false;
  int _gamesPlayed = 0;
  int _wins = 0;
  int _currentStreak = 0;
  int _gameNumber = 1;

  final List<ChatMessage> _chatMessages = [];

  bool _showEasterEgg = false;
  int _logoClickCount = 0;

  // Getters
  GameMode get gameMode => _gameMode;
  String get targetValue => _targetValue;
  int get mathTarget => _mathTarget;
  List<String> get guesses => List.unmodifiable(_guesses);
  String get currentGuess => _currentGuess;
  GameState get gameState => _gameState;
  String? get errorMessage => _errorMessage;
  int get shakeTrigger => _shakeTrigger;
  bool get showConfetti => _showConfetti;
  List<int> get countdownNumbers => _countdownNumbers;
  String get username => _username;
  bool get isLoggedIn => _isLoggedIn;
  int get gamesPlayed => _gamesPlayed;
  int get wins => _wins;
  int get currentStreak => _currentStreak;
  int get gameNumber => _gameNumber;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get showEasterEgg => _showEasterEgg;

  NortleController() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs.getString('username') ?? "";
    _isLoggedIn = _username.isNotEmpty;
    _gamesPlayed = _prefs.getInt('games_played') ?? 0;
    _wins = _prefs.getInt('wins') ?? 0;
    _currentStreak = _prefs.getInt('streak') ?? 0;

    _checkDailyReset();
    _listenForMessages();
    resetGame(GameMode.words);
    notifyListeners();
  }

  void _checkDailyReset() {
    final today = DateFormat('yyyyDDD').format(DateTime.now());
    final lastDate = _prefs.getString('last_play_date') ?? "";
    if (today != lastDate) {
      _prefs.setString('last_play_date', today);
      _prefs.setInt('games_today', 0);
    }
    _updateGameNumber();
  }

  void _updateGameNumber() {
    _gameNumber = (_prefs.getInt('games_today') ?? 0) + 1;
  }

  int _getDailySeed() {
    final now = DateTime.now();
    return now.year * 1000 + int.parse(DateFormat('D').format(now));
  }

  void _listenForMessages() {
    _dbRef.limitToLast(50).onValue.listen((event) {
      _chatMessages.clear();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          _chatMessages.add(ChatMessage.fromJson(value));
        });
        _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      notifyListeners();
    });
  }

  void login(String name) {
    if (name.trim().isNotEmpty) {
      _username = name.trim();
      _isLoggedIn = true;
      _prefs.setString('username', _username);
      notifyListeners();
    }
  }

  void logout() {
    _username = "";
    _isLoggedIn = false;
    _prefs.remove('username');
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (text.trim().isNotEmpty) {
      final message = ChatMessage(
        sender: _username,
        text: text.trim(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: MessageType.text,
      );
      _dbRef.push().set(message.toJson());
    }
  }

  String getFormattedDate() => DateFormat('dd/MM/yyyy').format(DateTime.now());

  void shareResult() {
    if (_gameState == GameState.playing) return;
    final resultGrid = _guesses.map((guess) {
      final rowIndex = _guesses.indexOf(guess);
      final sb = StringBuffer();
      final cols = _gameMode == GameMode.words ? 5 : 7;
      for (int i = 0; i < cols; i++) {
        final status = getLetterStatus(rowIndex, i);
        if (status == LetterStatus.correctPosition) {
          sb.write('G');
        } else if (status == LetterStatus.wrongPosition) {
          sb.write('Y');
        } else {
          sb.write('B');
        }
      }
      return sb.toString();
    }).toList();

    final message = ChatMessage(
      sender: _username,
      text: "Daily Challenge ${getFormattedDate()} V$_gameNumber\nSolved the ${_gameMode == GameMode.words ? "Word" : "Countdown"} puzzle in ${_guesses.length}/6 attempts!",
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: MessageType.result,
      resultGrid: resultGrid,
      target: _gameMode == GameMode.words ? _targetValue : _mathTarget.toString(),
      gameMode: _gameMode == GameMode.words ? "Word" : "Countdown",
    );

    _dbRef.push().set(message.toJson()).then((_) {
      _errorMessage = "Result shared to chat!";
      notifyListeners();
    }).catchError((error) {
      _errorMessage = "Share failed: $error";
      notifyListeners();
    });
  }

  void startCountdown(int largeCount) {
    _largeNumbersSelected = largeCount;
    final largePool = [25, 50, 75, 100];
    final smallPool = List.generate(10, (i) => [i + 1, i + 1]).expand((i) => i).toList();
    final random = Random();

    final chosen = <int>[];
    for (int i = 0; i < largeCount; i++) {
      chosen.add(largePool.removeAt(random.nextInt(largePool.length)));
    }
    for (int i = 0; i < 6 - largeCount; i++) {
      chosen.add(smallPool.removeAt(random.nextInt(smallPool.length)));
    }

    _countdownNumbers = chosen..sort((a, b) => b.compareTo(a));
    _mathTarget = random.nextInt(899) + 101;
    _gameState = GameState.playing;
    notifyListeners();
  }

  void resetGame(GameMode mode) {
    _gameMode = mode;
    _errorMessage = null;
    _showConfetti = false;
    _guesses.clear();
    _currentGuess = "";

    if (mode == GameMode.words) {
      final seed = _getDailySeed() + ((_prefs.getInt('games_today') ?? 0) * 1000);
      _targetValue = targetWords[Random(seed).nextInt(targetWords.length)];
      _gameState = GameState.playing;
    } else {
      _gameState = GameState.selectingNumbers;
    }
    notifyListeners();
  }

  void onKeyPress(String text) {
    if (_gameState != GameState.playing) return;
    _errorMessage = null;
    if (_gameMode == GameMode.words) {
      if (_currentGuess.length < 5) _currentGuess += text.toUpperCase();
    } else {
      if (_currentGuess.length < 40) _currentGuess += text;
    }
    notifyListeners();
  }

  void onDelete() {
    if (_gameState != GameState.playing) return;
    _errorMessage = null;
    if (_currentGuess.isNotEmpty) {
      if (_gameMode == GameMode.numbers) {
        final lastChar = _currentGuess[_currentGuess.length - 1];
        if (RegExp(r'\d').hasMatch(lastChar)) {
          int i = _currentGuess.length - 1;
          while (i >= 0 && RegExp(r'\d').hasMatch(_currentGuess[i])) {
            i--;
          }
          _currentGuess = _currentGuess.substring(0, i + 1);
        } else {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        }
      } else {
        _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
      }
    }
    notifyListeners();
  }

  void onSubmit() {
    if (_gameState != GameState.playing) return;
    if (_gameMode == GameMode.words) {
      if (_currentGuess.length == 5) {
        if (validUKDictionary.contains(_currentGuess)) {
          _guesses.add(_currentGuess);
          if (_currentGuess == _targetValue) {
            _onWin();
          } else if (_guesses.length == 6) {
            _onLoss();
          } else {
            _triggerFartAndShake();
          }
          _currentGuess = "";
        } else {
          _errorMessage = "Not in UK Dictionary";
          _triggerFartAndShake();
        }
      }
    } else {
      _validateCountdown();
    }
    notifyListeners();
  }

  void _validateCountdown() {
    final res = _evaluateCountdown(_currentGuess);
    if (res == null) {
      _triggerFartAndShake();
      return;
    }

    _guesses.add(_currentGuess);
    if (res == _mathTarget) {
      _onWin();
    } else if (_guesses.length == 6) {
      _onLoss();
    } else {
      _errorMessage = "Result: $res (Need $_mathTarget)";
      _triggerFartAndShake();
    }
    _currentGuess = "";
  }

  int? _evaluateCountdown(String expr) {
    try {
      final usedNumbers = <int>[];
      final numberRegex = RegExp(r'\d+');
      for (final match in numberRegex.allMatches(expr)) {
        usedNumbers.add(int.parse(match.group(0)!));
      }

      final tempPool = List<int>.from(_countdownNumbers);
      for (final num in usedNumbers) {
        if (!tempPool.remove(num)) {
          _errorMessage = "$num not available";
          return null;
        }
      }
      return _evaluateStrict(expr);
    } catch (e) {
      _errorMessage = "Invalid Equation";
      return null;
    }
  }

  int _evaluateStrict(String expr) {
    final tokens = _tokenize(expr);
    return _parseCountdownExpression(tokens);
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    int i = 0;
    while (i < expr.length) {
      final c = expr[i];
      if (RegExp(r'\d').hasMatch(c)) {
        final sb = StringBuffer();
        while (i < expr.length && RegExp(r'\d').hasMatch(expr[i])) {
          sb.write(expr[i++]);
        }
        tokens.add(sb.toString());
      } else if ("+-*/()".contains(c)) {
        tokens.add(expr[i++]);
      } else {
        i++;
      }
    }
    return tokens;
  }

  int _pos = 0;
  int _parseCountdownExpression(List<String> tokens) {
    _pos = 0;
    return tokens.isEmpty ? 0 : _countdownExpression(tokens);
  }

  int _countdownExpression(List<String> tokens) {
    int res = _countdownTerm(tokens);
    while (_pos < tokens.length && (tokens[_pos] == "+" || tokens[_pos] == "-")) {
      final op = tokens[_pos++];
      final b = _countdownTerm(tokens);
      if (op == "+") {
        res += b;
      } else {
        if (res - b < 0) throw Exception("Negative");
        res -= b;
      }
    }
    return res;
  }

  int _countdownTerm(List<String> tokens) {
    int res = _countdownFactor(tokens);
    while (_pos < tokens.length && (tokens[_pos] == "*" || tokens[_pos] == "/")) {
      final op = tokens[_pos++];
      final b = _countdownFactor(tokens);
      if (op == "*") {
        res *= b;
      } else {
        if (b == 0 || res % b != 0) throw Exception("Fractional");
        res ~/= b;
      }
    }
    return res;
  }

  int _countdownFactor(List<String> tokens) {
    if (_pos >= tokens.length) return 0;
    if (tokens[_pos] == "(") {
      _pos++;
      final res = _countdownExpression(tokens);
      if (_pos < tokens.length && tokens[_pos] == ")") _pos++;
      return res;
    }
    return int.parse(tokens[_pos++]);
  }

  void _triggerFartAndShake() {
    _shakeTrigger++;
    _playSound("fart.mp3");
  }

  void _playSound(String fileName) async {
    await _audioPlayer.play(AssetSource('sounds/$fileName'));
  }

  void _onWin() {
    _gameState = GameState.won;
    _wins++;
    _currentStreak++;
    _gamesPlayed++;
    _showConfetti = true;
    _playSound("winner.mp3");
    _updateStats();
  }

  void _onLoss() {
    _gameState = GameState.lost;
    _currentStreak = 0;
    _gamesPlayed++;
    _updateStats();
  }

  void _updateStats() {
    final todayCount = (_prefs.getInt('games_today') ?? 0) + 1;
    _prefs.setInt('games_played', _gamesPlayed);
    _prefs.setInt('wins', _wins);
    _prefs.setInt('streak', _currentStreak);
    _prefs.setInt('games_today', todayCount);
    _updateGameNumber();
  }

  LetterStatus getLetterStatus(int guessIndex, int colIndex) {
    if (_gameMode == GameMode.words) {
      if (guessIndex >= _guesses.length) return LetterStatus.empty;
      final guess = _guesses[guessIndex];
      final target = _targetValue;
      if (colIndex >= guess.length) return LetterStatus.empty;
      final char = guess[colIndex];
      if (char == target[colIndex]) return LetterStatus.correctPosition;

      int totalInTarget = 0;
      for (int i = 0; i < target.length; i++) {
        if (target[i] == char) totalInTarget++;
      }

      int markedGreen = 0;
      for (int i = 0; i < guess.length && i < target.length; i++) {
        if (guess[i] == char && target[i] == char) markedGreen++;
      }

      int prevYellow = 0;
      for (int i = 0; i < colIndex; i++) {
        if (guess[i] == char && (i >= target.length || target[i] != char) && target.contains(char)) {
          prevYellow++;
        }
      }

      return (target.contains(char) && (prevYellow < (totalInTarget - markedGreen)))
          ? LetterStatus.wrongPosition
          : LetterStatus.notInWord;
    } else {
      return LetterStatus.empty;
    }
  }

  LetterStatus getKeyStatus(String char) {
    if (_gameMode != GameMode.words) return LetterStatus.empty;

    LetterStatus bestStatus = LetterStatus.empty;
    for (final guess in _guesses) {
      for (int i = 0; i < guess.length; i++) {
        if (guess[i] == char) {
          LetterStatus status;
          if (guess[i] == _targetValue[i]) {
            status = LetterStatus.correctPosition;
          } else if (_targetValue.contains(guess[i])) {
            status = LetterStatus.wrongPosition;
          } else {
            status = LetterStatus.notInWord;
          }

          if (status == LetterStatus.correctPosition) return LetterStatus.correctPosition;
          if (status == LetterStatus.wrongPosition && bestStatus != LetterStatus.correctPosition) {
            bestStatus = LetterStatus.wrongPosition;
          }
          if (status == LetterStatus.notInWord && bestStatus == LetterStatus.empty) {
            bestStatus = LetterStatus.notInWord;
          }
        }
      }
    }
    return bestStatus;
  }

  void onLogoClick() {
    _logoClickCount++;
    if (_logoClickCount >= 5) {
      _showEasterEgg = true;
      _logoClickCount = 0;
      notifyListeners();
    }
  }

  void dismissEasterEgg() {
    _showEasterEgg = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
