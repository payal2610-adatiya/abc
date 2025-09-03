import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(home: LoginScreen(), debugShowCheckedModeBanner: false));
}


class GameHistory {
  final String gameType;
  final int score;
  final DateTime timestamp;

  GameHistory({
    required this.gameType,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameType': gameType,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameHistory.fromMap(Map<String, dynamic> map) {
    return GameHistory(
      gameType: map['gameType'],
      score: map['score'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bool isLoggedIn = sharedPreferences.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboardscreen()));
    }
  }

  void login() async {
    if (_formKey.currentState!.validate()) {
      sharedPreferences = await SharedPreferences.getInstance();
      sharedPreferences.setBool('isLoggedIn', true);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboardscreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value!.isEmpty) {
                    return ' Please Enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Screen with Game History
class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  State<Dashboardscreen> createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  int currentIndex = 0;
  List<GameHistory> gameHistory = [];

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
  }

  Future<void> _loadGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('gameHistory') ?? [];

    setState(() {
      gameHistory = historyJson
          .map((json) => GameHistory.fromMap(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _addGameHistory(GameHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('gameHistory') ?? [];

    // Add new history and keep only last 20 records
    historyJson.insert(0, jsonEncode(history.toMap()));
    if (historyJson.length > 20) {
      historyJson.removeLast();
    }

    await prefs.setStringList('gameHistory', historyJson);
    await _loadGameHistory(); // Reload history
  }

  void _showGameHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game History'),
        content: gameHistory.isEmpty
            ? Text('No game history yet!')
            : Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gameHistory.length,
            itemBuilder: (context, index) {
              final history = gameHistory[index];
              return ListTile(
                title: Text('${history.gameType}: ${history.score}'),
                subtitle: Text(
                    '${history.timestamp.day}/${history.timestamp.month}/${history.timestamp.year} '
                        '${history.timestamp.hour}:${history.timestamp.minute.toString().padLeft(2, '0')}'
                ),
                trailing: Icon(
                  history.gameType == 'Random Number' ? Icons.gamepad : Icons.touch_app,
                  color: Colors.blue,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (gameHistory.isNotEmpty)
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('gameHistory');
                await _loadGameHistory();
                Navigator.pop(context);
              },
              child: Text('Clear History', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          // Game History Menu Button
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'history') {
                _showGameHistory();
              } else if (value == 'logout') {
                logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Game History'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: currentIndex == 0
          ? RandomNumberGame(onGameEnd: _addGameHistory)
          : TapGame(onGameEnd: _addGameHistory),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Random Number Game'),
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Tap Challenge Game'),
        ],
      ),
    );
  }

  void logout() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('isLoggedIn', false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}

// Random Number Game with History
class RandomNumberGame extends StatefulWidget {
  final Function(GameHistory) onGameEnd;

  RandomNumberGame({required this.onGameEnd});

  @override
  _RandomNumberGameState createState() => _RandomNumberGameState();
}

class _RandomNumberGameState extends State<RandomNumberGame> {
  final Random random = Random();
  late int targetNumber;
  int numberOfGuesses = 0;
  final int maxGuesses = 5;
  String hintMessage = '';
  final TextEditingController guessController = TextEditingController();
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      targetNumber = random.nextInt(100) + 1;
      numberOfGuesses = 0;
      hintMessage = '';
      gameWon = false;
      guessController.clear();
    });
  }

  void _checkGuess() {
    final guess = int.tryParse(guessController.text);
    if (guess == null) {
      setState(() {
        hintMessage = 'Please enter a valid number';
      });
      return;
    }

    numberOfGuesses++;

    if (numberOfGuesses > maxGuesses) {
      setState(() {
        hintMessage = 'Game over! You have used all $maxGuesses guesses. The number was $targetNumber';
      });
      widget.onGameEnd(GameHistory(
        gameType: 'Random Number',
        score: 0, // 0 means lost
        timestamp: DateTime.now(),
      ));
      return;
    }

    if (guess > targetNumber) {
      hintMessage = 'Too high!';
    } else if (guess < targetNumber) {
      hintMessage = 'Too low!';
    } else {
      hintMessage = 'Correct! You won in $numberOfGuesses guesses!';
      gameWon = true;
      widget.onGameEnd(GameHistory(
        gameType: 'Random Number',
        score: numberOfGuesses, // Lower score is better
        timestamp: DateTime.now(),
      ));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Guess the Number (1-100)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: guessController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your guess',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkGuess,
              child: Text('Check Guess'),
            ),
            SizedBox(height: 20),
            Text(
              hintMessage,
              style: TextStyle(
                fontSize: 16,
                color: gameWon ? Colors.green : Colors.black,
                fontWeight: gameWon ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Guesses: $numberOfGuesses/$maxGuesses',
              style: TextStyle(fontSize: 16),
            ),
            if (hintMessage.isNotEmpty && !gameWon && numberOfGuesses >= maxGuesses)
              ElevatedButton(
                onPressed: _startNewGame,
                child: Text('Play Again'),
              ),
          ],
        ),
      ),
    );
  }
}

// Tap Game with History
class TapGame extends StatefulWidget {
  final Function(GameHistory) onGameEnd;

  TapGame({required this.onGameEnd});

  @override
  _TapGameState createState() => _TapGameState();
}

class _TapGameState extends State<TapGame> {
  int _tapCount = 0;
  int _timeLeft = 10;
  bool _gameStarted = false;
  Timer? _countdownTimer;

  void _startGame() {
    setState(() {
      _tapCount = 0;
      _timeLeft = 10;
      _gameStarted = true;
    });

    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _incrementTap() {
    if (_gameStarted && _timeLeft > 0) {
      setState(() {
        _tapCount++;
      });
    }
  }

  void _endGame() {
    setState(() {
      _gameStarted = false;
    });
    _countdownTimer?.cancel();

    // Save game result to history
    widget.onGameEnd(GameHistory(
      gameType: 'Tap Challenge',
      score: _tapCount,
      timestamp: DateTime.now(),
    ));
  }

  void _resetGame() {
    setState(() {
      _tapCount = 0;
      _timeLeft = 10;
      _gameStarted = false;
    });
    _countdownTimer?.cancel();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tap Challenge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Tap as many times as possible in 10 seconds',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            if (!_gameStarted && _tapCount == 0)
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('START GAME'),
              ),

            SizedBox(height: 20),

            Text(
              'Time Left: $_timeLeft seconds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Taps: $_tapCount',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            GestureDetector(
              onTap: _incrementTap,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _gameStarted && _timeLeft > 0 ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    _gameStarted && _timeLeft > 0 ? 'TAP!' : 'READY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            if (!_gameStarted && _tapCount > 0)
              Column(
                children: [
                  Text(
                    'GAME OVER!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your score: $_tapCount taps',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _resetGame,
                    child: Text('PLAY AGAIN'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
