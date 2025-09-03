import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(home: LoginScreen(), debugShowCheckedModeBanner: false));
}

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
      // Save login state
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
                    return 'Please enter your email';
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

class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  State<Dashboardscreen> createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: currentIndex == 0 ? RandomNumberGame() : TapGame(),
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

class RandomNumberGame extends StatefulWidget {
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
      return;
    }

    if (guess > targetNumber) {
      hintMessage = 'Too high!';
    } else if (guess < targetNumber) {
      hintMessage = 'Too low!';
    } else {
      hintMessage = 'Correct  You won in $numberOfGuesses guesses!';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Random Number Game'),
      ),
      body: Column(
        children: [
          Text('Guess the number (1-100):'),
          TextField(
            controller: guessController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter your guess',
            ),
          ),
          ElevatedButton(
            onPressed: _checkGuess,
            child: Text('Check Guess'),
          ),
          SizedBox(height: 20),
          Text(hintMessage),
        ],
      ),
    );
  }
}

class TapGame extends StatefulWidget {
  @override
  _TapGameState createState() => _TapGameState();
}

class _TapGameState extends State<TapGame> {
  int _tapCount = 0;
  int _timeLeft = 10;
  bool _gameStarted = false;

  void _startGame() {
    setState(() {
      _tapCount = 0;
      _timeLeft = 10;
      _gameStarted = true;
    });
    Future.delayed(Duration(seconds: 10), _endGame);
    _countDown();
  }

  void _countDown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _incrementTap() {
    if (_gameStarted) {
      setState(() {
        _tapCount++;
      });
    }
  }

  void _endGame() {
    setState(() {
      _gameStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tap Challenge Game'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap as many times as possible in 10 seconds'),
          GestureDetector(
            onTap: () {
              if (!_gameStarted) _startGame();
              _incrementTap();
            },
            child: Container(
              color: Colors.black12,
              height: 100,
              width: double.infinity,
              child: Center(
                child: Text(
                  'TAP ME!',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Taps: $_tapCount', style: TextStyle(fontSize: 20)),
          if (_gameStarted)
            Text('Time Left: $_timeLeft seconds', style: TextStyle(fontSize: 20)),
          if (!_gameStarted)
            Text('Game Over!', style: TextStyle(fontSize: 20)),

        ],
      ),
    );
  }
}
