import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _load();
  }

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'ng3_playlists.json');
  }

  Future<void> _load() async {
    try {
      final file = File(await _filePath);
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List;
        _playlists = list.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = File(await _filePath);
    await file.writeAsString(jsonEncode(_playlists.map((p) => p.toJson()).toList()));
  }

  Future<void> create(String name) async {
    _playlists.add(Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    ));
    notifyListeners();
    await _save();
  }

  Future<void> rename(String id, String name) async {
    _playlists.firstWhere((p) => p.id == id).name = name;
    notifyListeners();
    await _save();
  }

  Future<void> delete(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> addTrack(String playlistId, String trackPath) async {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    if (!pl.trackPaths.contains(trackPath)) {
      pl.trackPaths.add(trackPath);
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeTrack(String playlistId, String trackPath) async {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    pl.trackPaths.remove(trackPath);
    notifyListeners();
    await _save();
  }
}
