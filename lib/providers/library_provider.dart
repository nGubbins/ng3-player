import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class LibraryProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  bool _isLoading = false;
  double _loadProgress = 0;
  String? _libraryPath;
  String? _error;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  double get loadProgress => _loadProgress;
  String? get libraryPath => _libraryPath;
  String? get error => _error;
  bool get isEmpty => _tracks.isEmpty;

  Map<String, List<Track>> get albumMap {
    final m = <String, List<Track>>{};
    for (final t in _tracks) {
      m.putIfAbsent(t.album, () => []).add(t);
    }
    return m;
  }

  Map<String, List<Track>> get artistMap {
    final m = <String, List<Track>>{};
    for (final t in _tracks) {
      m.putIfAbsent(t.artist, () => []).add(t);
    }
    return m;
  }

  Map<String, List<Track>> get genreMap {
    final m = <String, List<Track>>{};
    for (final t in _tracks) {
      m.putIfAbsent(t.genre, () => []).add(t);
    }
    return m;
  }

  LibraryProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('library_path');
    if (saved != null && Directory(saved).existsSync()) {
      await loadLibrary(saved);
    }
  }

  Future<void> pickAndLoad() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Music Library Folder',
    );
    if (path != null) await loadLibrary(path);
  }

  Future<void> loadLibrary(String path) async {
    _isLoading = true;
    _loadProgress = 0;
    _error = null;
    _libraryPath = path;
    notifyListeners();

    try {
      final files = <File>[];
      await for (final e in Directory(path).list(recursive: true, followLinks: false)) {
        if (e is File && _isSupportedAudio(e.path)) {
          files.add(e);
        }
      }

      final tracks = <Track>[];
      for (int i = 0; i < files.length; i++) {
        try {
          final meta = await MetadataGod.readMetadata(file: files[i].path);
          final name = p.basenameWithoutExtension(files[i].path);
          tracks.add(Track(
            filePath: files[i].path,
            title: _clean(meta.title) ?? name,
            artist: _clean(meta.artist) ?? 'Unknown Artist',
            albumArtist: _clean(meta.albumArtist) ?? _clean(meta.artist) ?? 'Unknown Artist',
            album: _clean(meta.album) ?? 'Unknown Album',
            genre: _clean(meta.genre) ?? 'Unknown Genre',
            year: meta.year,
            trackNumber: meta.trackNumber,
            duration: Duration(milliseconds: (meta.durationMs ?? 0).round()),
            albumArt: meta.picture?.data,
          ));
        } catch (_) {
          // skip unreadable files
        }
        _loadProgress = (i + 1) / files.length;
        if (i % 10 == 0) notifyListeners();
      }

      _tracks = tracks;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('library_path', path);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _loadProgress = 1;
      notifyListeners();
    }
  }

  static const _supportedExtensions = {'.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'};

  bool _isSupportedAudio(String path) {
    final ext = path.toLowerCase();
    return _supportedExtensions.any(ext.endsWith);
  }

  String? _clean(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }
}
