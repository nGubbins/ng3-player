# ng3

A local music player for Windows and Android. Point it at a folder of MP3s and it builds your library automatically — no accounts, no cloud, no tracking.

## Features

- **Library tabs** — browse by All Tracks, Albums, Artists, Genres, or Playlists
- **Search and sort** within every tab
- **Album art** read directly from MP3 tags
- **Now playing panel** — mini bar at the bottom expands to a full player with seek bar, ±10 s skip, shuffle, repeat-one, and repeat-all
- **User playlists** — create, rename, delete, and add tracks from anywhere in the library
- **Persistent library** — remembers your folder between sessions

## Download

Grab the latest build from the [Releases](https://github.com/nGubbins/ng3-player/releases) page:

- **Windows** — extract the zip and run `ng3.exe`
- **Android** — install the APK (enable *Install unknown apps* for your browser/file manager)

## Build from source

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel), JDK 17+ (Android only)

```bash
git clone https://github.com/nGubbins/ng3-player.git
cd ng3-player
flutter pub get

flutter run -d windows   # Windows desktop
flutter run -d android   # connected Android device
```

## Platform support

| Platform | Status |
|---|---|
| Windows | Primary target — release builds available |
| Android | Release APK available |
| iOS / macOS / Linux / Web | Not tested |

## License

[MIT](LICENSE)
