import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  final List<Track> tracks;

  const PlaylistDetailScreen({super.key, required this.playlist, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (tracks.isNotEmpty)
            FilledButton.icon(
              onPressed: () => context.read<PlayerProvider>().playQueue(tracks, 0),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Play all'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('No tracks in this playlist'),
                  const SizedBox(height: 6),
                  Text('Long-press any track and choose "Add to playlist"',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: tracks.length,
              itemBuilder: (_, i) => TrackTile(
                track: tracks[i],
                isPlaying: player.currentTrack?.filePath == tracks[i].filePath,
                onTap: () => context.read<PlayerProvider>().playQueue(tracks, i),
              ),
            ),
    );
  }
}
