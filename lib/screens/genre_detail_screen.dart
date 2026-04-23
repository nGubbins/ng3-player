import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';

class GenreDetailScreen extends StatelessWidget {
  final String genre;
  final List<Track> tracks;

  const GenreDetailScreen({super.key, required this.genre, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(tracks)..sort((a, b) => a.title.compareTo(b.title));
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(genre),
        actions: [
          FilledButton.icon(
            onPressed: () => context.read<PlayerProvider>().playQueue(sorted, 0),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Play all'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sorted.length,
        itemBuilder: (_, i) => TrackTile(
          track: sorted[i],
          isPlaying: player.currentTrack?.filePath == sorted[i].filePath,
          onTap: () => context.read<PlayerProvider>().playQueue(sorted, i),
        ),
      ),
    );
  }
}
