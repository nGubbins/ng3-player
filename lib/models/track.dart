import 'dart:typed_data';

class Track {
  final String filePath;
  final String title;
  final String artist;
  final String albumArtist;
  final String album;
  final String genre;
  final int? year;
  final int? trackNumber;
  final Duration duration;
  final Uint8List? albumArt;

  const Track({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.albumArtist,
    required this.album,
    required this.genre,
    this.year,
    this.trackNumber,
    required this.duration,
    this.albumArt,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'title': title,
        'artist': artist,
        'albumArtist': albumArtist,
        'album': album,
        'genre': genre,
        'year': year,
        'trackNumber': trackNumber,
        'durationMs': duration.inMilliseconds,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        filePath: json['filePath'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        albumArtist: json['albumArtist'] as String,
        album: json['album'] as String,
        genre: json['genre'] as String,
        year: json['year'] as int?,
        trackNumber: json['trackNumber'] as int?,
        duration: Duration(milliseconds: (json['durationMs'] as int? ?? 0)),
        albumArt: null,
      );
}
