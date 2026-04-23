import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/track.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Track> _queue = [];
  List<Track> _originalQueue = [];
  int _currentIndex = -1;
  PlaybackMode _mode = PlaybackMode.regular;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Track? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  PlaybackMode get mode => _mode;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;

  PlayerProvider() {
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) => _onComplete());
  }

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    _originalQueue = List.from(tracks);
    if (_mode == PlaybackMode.shuffle) {
      _queue = List.from(tracks)..shuffle(Random());
      _currentIndex = 0;
    } else {
      _queue = List.from(tracks);
      _currentIndex = startIndex.clamp(0, tracks.length - 1);
    }
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    final track = _queue[_currentIndex];
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    await _player.play(DeviceFileSource(track.filePath));
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position.isNegative ? Duration.zero : position);
  }

  Future<void> seekForward() async => seek(_position + const Duration(seconds: 10));

  Future<void> seekBack() async => seek(_position - const Duration(seconds: 10));

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_mode == PlaybackMode.repeatOne) {
      await seek(Duration.zero);
      await _player.resume();
      return;
    }
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_mode == PlaybackMode.repeatAll || _mode == PlaybackMode.shuffle) {
      _currentIndex = 0;
    } else {
      return;
    }
    await _playCurrent();
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_mode == PlaybackMode.repeatAll || _mode == PlaybackMode.shuffle) {
      _currentIndex = _queue.length - 1;
    }
    await _playCurrent();
  }

  void setMode(PlaybackMode mode) {
    final wasShuffled = _mode == PlaybackMode.shuffle;
    final nowShuffled = mode == PlaybackMode.shuffle;
    _mode = mode;

    if (nowShuffled && !wasShuffled && _queue.isNotEmpty) {
      final current = currentTrack;
      _queue = List.from(_originalQueue)..shuffle(Random());
      if (current != null) {
        final idx = _queue.indexOf(current);
        _currentIndex = idx >= 0 ? idx : 0;
      }
    } else if (!nowShuffled && wasShuffled && _originalQueue.isNotEmpty) {
      final current = currentTrack;
      _queue = List.from(_originalQueue);
      if (current != null) {
        final idx = _queue.indexOf(current);
        _currentIndex = idx >= 0 ? idx : 0;
      }
    }
    notifyListeners();
  }

  void _onComplete() {
    switch (_mode) {
      case PlaybackMode.repeatOne:
        _playCurrent();
      case PlaybackMode.repeatAll:
        _currentIndex = (_currentIndex + 1) % _queue.length;
        _playCurrent();
      case PlaybackMode.shuffle:
      case PlaybackMode.regular:
        if (_currentIndex < _queue.length - 1) {
          _currentIndex++;
          _playCurrent();
        } else {
          _isPlaying = false;
          notifyListeners();
        }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
