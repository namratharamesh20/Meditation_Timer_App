import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MeditationApp());
}

class MeditationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MeditationTimer(),
    );
  }
}

class MeditationTimer extends StatefulWidget {
  @override
  _MeditationTimerState createState() => _MeditationTimerState();
}

class _MeditationTimerState extends State<MeditationTimer> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  int _durationMinutes = 1;
  int _streak = 0;
  String _selectedMood = "Calm";

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _moodToSound = {
    "Calm": "peace.mp3",
    "Relaxed": "rain.mp3",
    "Healing": "heal.mp3",
  };

  String _quote = "Breathe in... Breathe out...";
  bool _showBreathPacer = false;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streak = prefs.getInt('streak') ?? 0;
    });
  }

  Future<void> _incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streak += 1;
    });
    await prefs.setInt('streak', _streak);
  }

  void _startTimer() async {
    if (_isRunning) return;
    _isRunning = true;
    _playSound();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;

        if (_elapsedSeconds >= _durationMinutes * 60) {
          _stopTimer();
          _showCompletedDialog();
          _incrementStreak();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _audioPlayer.stop();
  }

  void _restartTimer() {
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  void _playSound() async {
    String? filename = _moodToSound[_selectedMood];
    if (filename != null) {
      await _audioPlayer.play(AssetSource('sounds/$filename'));
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Session Complete"),
        content: Text("Well done! You've completed your meditation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildBreathPacer() {
    return AnimatedContainer(
      duration: Duration(seconds: 4),
      width: _isRunning ? 150 : 50,
      height: _isRunning ? 150 : 50,
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.blueGrey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  "Mood: $_selectedMood",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                DropdownButton<String>(
                  value: _selectedMood,
                  dropdownColor: Colors.white,
                  items: _moodToSound.keys.map((String mood) {
                    return DropdownMenuItem<String>(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                  onChanged: (String? newMood) {
                    if (!_isRunning) {
                      setState(() {
                        _selectedMood = newMood!;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                Text(
                  "Set Timer: $_durationMinutes min",
                  style: TextStyle(fontSize: 18),
                ),
                Slider(
                  min: 1,
                  max: 60,
                  divisions: 59,
                  value: _durationMinutes.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _durationMinutes = value.toInt();
                    });
                  },
                ),
                SizedBox(height: 10),
                Text(
                  "Timer: ${_formatTime(_elapsedSeconds)}",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                _buildBreathPacer(),
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _elapsedSeconds / (_durationMinutes * 60),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.teal,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startTimer,
                  child: Text("Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(160, 50),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _stopTimer,
                  child: Text("Stop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(160, 50),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _restartTimer,
                  child: Text("Restart"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(160, 50),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Current Streak: $_streak day${_streak == 1 ? '' : 's'}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
