class Playlist {
  final String id;
  String name;
  final List<String> trackPaths;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    List<String>? trackPaths,
    DateTime? createdAt,
  })  : trackPaths = trackPaths ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trackPaths': trackPaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        trackPaths: List<String>.from(json['trackPaths'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
