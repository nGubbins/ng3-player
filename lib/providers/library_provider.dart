import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
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
    if (saved == null) return;

    final resolved = _resolveAndroidPath(saved);
    try {
      if (Directory(resolved).existsSync()) {
        await loadLibrary(resolved);
      }
    } catch (_) {
      // Saved path from a prior version may be invalid; user must re-pick.
    }
  }

  Future<void> pickAndLoad() async {
    if (Platform.isAndroid) {
      final granted = await _requestAndroidAudioPermission();
      if (!granted) {
        _error = 'Storage permission denied. Please grant it in app settings.';
        notifyListeners();
        return;
      }
    }

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Music Library Folder',
    );
    if (path == null) return;

    await loadLibrary(_resolveAndroidPath(path));
  }

  // Requests audio/storage permission on Android and returns whether access was granted.
  Future<bool> _requestAndroidAudioPermission() async {
    if (await Permission.audio.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    var status = await Permission.audio.request();
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    return status.isGranted;
  }

  // Converts Android SAF content URIs to real file-system paths.
  // content://com.android.externalstorage.documents/tree/primary%3AMusic
  // → /storage/emulated/0/Music
  String _resolveAndroidPath(String path) {
    if (!Platform.isAndroid) return path;
    if (!path.startsWith('content://com.android.externalstorage.documents')) {
      return path;
    }
    try {
      final decoded = Uri.decodeFull(path);
      final match = RegExp(r'/tree/([^:/]+):(.*)$').firstMatch(decoded);
      if (match == null) return path;
      final storage = match.group(1)!;
      final relative = match.group(2)!;
      final base = storage == 'primary' ? '/storage/emulated/0' : '/storage/$storage';
      return relative.isEmpty ? base : '$base/$relative';
    } catch (_) {
      return path;
    }
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
