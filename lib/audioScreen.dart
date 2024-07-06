import 'dart:async';

import 'package:audio_app/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioRecorderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioRecorder(),
      theme: ThemeData.dark(),
    );
  }
}

class AudioRecorder extends StatefulWidget {
  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _Recording {
  String filePath;
  int duration;

  _Recording(this.filePath, this.duration);
}

class _AudioRecorderState extends State<AudioRecorder> {
  static const platform = MethodChannel('audio_recorder');
  String _status = 'Idle';
  List<_Recording> _recordings = [];
  Timer? _timer;
  int _recordingTime = 0;
  bool _isRecording = false;
  int _currentlyPlayingIndex = -1;
  List<Timer?> _recordingTimers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  @override
  void dispose() {
    _stopAllTimers();
    super.dispose();
  }

  void _stopAllTimers() {
    for (var timer in _recordingTimers) {
      timer?.cancel();
    }
  }

  Future<void> _startRecording() async {
    try {
      final result = await platform.invokeMethod('startRecording');
      setState(() {
        _status = result;
        _recordingTime = 0;
        _startTimer();
        _isRecording = true;
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Failed to start recording: '${e.message}'.";
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await platform.invokeMethod('stopRecording');
      setState(() {
        _status = result;
        _stopTimer();
        _loadRecordings();
        _isRecording = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Failed to stop recording: '${e.message}'.";
      });
    }
  }

  Future<void> _loadRecordings() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getRecordings');
      setState(() {
        _recordings.clear();
        _recordings = result.map((filePath) => _Recording(filePath, 0)).toList();
        _recordingTimers = List.generate(_recordings.length, (_) => null);
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Failed to load recordings: '${e.message}'.";
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordingTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int time) {
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _playRecording(String filePath, int index) async {
    try {
      final result =
          await platform.invokeMethod('playRecording', {'filePath': filePath});
      setState(() {
        _status = result;
        _currentlyPlayingIndex = index;
        _recordingTime = 0;
        _startIndividualTimer(index);
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Failed to play recording: '${e.message}'.";
      });
    }
  }

  void _startIndividualTimer(int index) {
    _stopAllTimers();
    _recordingTimers[index] = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordings[index].duration++;
      });
    });
  }

  Future<void> _stopPlayback() async {
    try {
      final result = await platform.invokeMethod('stopPlayback');
      setState(() {
        _status = result;
        _stopIndividualTimer(_currentlyPlayingIndex);
        _currentlyPlayingIndex = -1;
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Failed to stop playback: '${e.message}'.";
      });
    }
  }

  void _stopIndividualTimer(int index) {
    _recordingTimers[index]?.cancel();
    _recordingTimers[index] = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
       appBar: AppBar(
        title: Text(
          'A A V A A Z',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.menu , color: Colors.white,),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Implement your logout functionality here
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: _recordingTime / 60.0,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      _formatTime(_recordingTime),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildControls(),
            SizedBox(height: 20),
            Expanded(
              child: _buildRecentRecordings(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.stop, color: Colors.white),
          iconSize: 40,
          onPressed: _isRecording ? _stopRecording : null,
        ),
        SizedBox(width: 20),
        FloatingActionButton(
          onPressed: _isRecording ? null : _startRecording,
          child: Icon(_isRecording ? Icons.pause : Icons.mic),
          backgroundColor: Colors.red,
        ),
        SizedBox(width: 20),
      ],
    );
  }

  Widget _buildRecentRecordings() {
    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final recording = _recordings[index];
        return Dismissible(
          key: Key(recording.filePath),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _deleteRecording(index);
          },
          direction: DismissDirection.endToStart,
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                index == _currentlyPlayingIndex ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: index == _currentlyPlayingIndex
                  ? _stopPlayback
                  : () => _playRecording(recording.filePath, index),
            ),
            title: Text('Recording ${index + 1}', style: TextStyle(color: Colors.white)),
            subtitle: Text(recording.filePath, style: TextStyle(color: Colors.grey)),
            trailing: Text(_formatTime(recording.duration), style: TextStyle(color: Colors.white)),
            onTap: index == _currentlyPlayingIndex
                ? _stopPlayback
                : () => _playRecording(recording.filePath, index),
          ),
        );
      },
    );
  }

  void _deleteRecording(int index) {
    setState(() {
      _recordings.removeAt(index);
      _recordingTimers[index]?.cancel();
      _recordingTimers.removeAt(index);
      _currentlyPlayingIndex = -1;
    });
    // Optionally, delete the actual file from storage using platform method
  }
}

