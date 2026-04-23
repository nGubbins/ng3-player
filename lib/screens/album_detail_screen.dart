import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';
import '../widgets/album_art.dart';
import '../widgets/track_tile.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<Track> tracks;

  const AlbumDetailScreen({super.key, required this.albumName, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(tracks)
      ..sort((a, b) => (a.trackNumber ?? 999).compareTo(b.trackNumber ?? 999));
    final player = context.watch<PlayerProvider>();
    final art = sorted.map((t) => t.albumArt).firstWhere((a) => a != null, orElse: () => null);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(albumName, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: AlbumArt(data: art, size: double.infinity, borderRadius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sorted.first.albumArtist,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (sorted.first.year != null)
                        Text('${sorted.first.year}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => context.read<PlayerProvider>().playQueue(sorted, 0),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Play all'),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => TrackTile(
                track: sorted[i],
                isPlaying: player.currentTrack?.filePath == sorted[i].filePath,
                onTap: () => context.read<PlayerProvider>().playQueue(sorted, i),
              ),
              childCount: sorted.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
