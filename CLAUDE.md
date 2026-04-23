# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
flutter run                  # Run on default connected device
flutter run -d windows       # Run on Windows desktop
flutter run -d chrome        # Run on web (Chrome)

# Testing
flutter test                 # Run all tests
flutter test test/widget_test.dart  # Run a single test file

# Analysis
flutter analyze              # Run Dart analyzer (flutter_lints rules)

# Build
flutter build windows        # Windows release build
flutter build web            # Build web release
flutter build apk            # Android APK

# Dependencies
flutter pub get              # Install/update dependencies
```

## Architecture

**ng3** is a Flutter local MP3 player targeting Windows (primary), Android, iOS, macOS, Linux, and Web.

### Source layout

```
lib/
  main.dart                    # App root + MultiProvider setup
  models/
    track.dart                 # Track model (filePath, title, artist, album, albumArt, …)
    playlist.dart              # Playlist model (id, name, trackPaths, toJson/fromJson)
    enums.dart                 # PlaybackMode, TrackSort, AlbumSort, ArtistSort, GenreSort
  utils/
    format_utils.dart          # formatDuration(Duration) → "m:ss" / "h:mm:ss"
  providers/
    library_provider.dart      # Scans mp3 files via metadata_god; saves path to shared_prefs
    player_provider.dart       # Wraps audioplayers AudioPlayer; owns queue + PlaybackMode
    playlist_provider.dart     # CRUD for user playlists; persists to JSON in app documents dir
  screens/
    home_screen.dart           # TabController, loading/empty states, NowPlayingPanel overlay
    album_detail_screen.dart   # Tracks in an album (sorted by trackNumber)
    artist_detail_screen.dart  # Albums + collapsible track list for one artist
    genre_detail_screen.dart   # Tracks in a genre
    playlist_detail_screen.dart# Tracks in a user playlist
  tabs/
    all_tracks_tab.dart        # Search + sort + TrackTile list
    albums_tab.dart            # Search + sort + album grid → AlbumDetailScreen
    artists_tab.dart           # Search + sort + artist list → ArtistDetailScreen
    genres_tab.dart            # Search + sort + genre list → GenreDetailScreen
    playlists_tab.dart         # Playlist CRUD UI + list → PlaylistDetailScreen
  widgets/
    now_playing_panel.dart     # Animated mini↔full player overlay (Positioned + AnimatedContainer)
    track_tile.dart            # ListTile with albumArt, title, artist, duration, add-to-playlist menu
    album_art.dart             # AlbumArt widget (Image.memory or placeholder icon)
```

### State management

Three `ChangeNotifier` providers composed via `MultiProvider`:
- **`LibraryProvider`** — loads MP3 metadata on startup (auto-reloads saved path) or when `pickAndLoad()` is called. Exposes `tracks`, `albumMap`, `artistMap`, `genreMap`, loading progress.
- **`PlayerProvider`** — wraps `AudioPlayer` from `audioplayers`. Owns `_queue`, `_currentIndex`, `_mode` (regular/shuffle/repeatOne/repeatAll). `playQueue(tracks, startIndex)` is the main entry point for starting playback.
- **`PlaylistProvider`** — user-created playlists stored as JSON at `<app_documents>/ng3_playlists.json`.

### Key packages

| Package | Purpose |
|---|---|
| `audioplayers` | Audio playback (`DeviceFileSource` for local files) |
| `metadata_god` | MP3 tag reading — use `MetadataGod.getMetadata(path)` (no init call needed) |
| `file_picker` | Native directory picker (`FilePicker.platform.getDirectoryPath()`) |
| `provider` | State management |
| `shared_preferences` | Persisting the library folder path |
| `path_provider` | Locating the app documents directory for playlist JSON |

### Now playing panel

`NowPlayingPanel` sits in a `Positioned` overlay inside `HomeScreen`'s `Stack`. It uses `AnimatedContainer` to transition between 72 px (mini) and `MediaQuery.of(context).size.height` (full). Mini player shows art + title + prev/play/next. Full player adds seek bar, ±10 s buttons, and mode toggles (shuffle / repeat-all → repeat-one cycle).

### Adding tracks to a playlist

`TrackTile` popup menu calls `PlaylistProvider.addTrack(playlistId, filePath)`. The Playlists tab and playlist detail screen resolve track paths back to `Track` objects via `LibraryProvider.tracks`.

## Notes

- `test/widget_test.dart` references the old skeleton widget — update it before relying on CI.
- `windows/flutter/ephemeral/` and `.dart_tool/` are auto-generated; never edit or commit them.
- Windows requires Developer Mode enabled for native plugin symlinks (`flutter build windows` will prompt if missing).
