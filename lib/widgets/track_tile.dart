import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/playlist_provider.dart';
import '../utils/format_utils.dart';
import 'album_art.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: AlbumArt(data: track.albumArt, size: 48),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isPlaying ? TextStyle(color: scheme.primary, fontWeight: FontWeight.w600) : null,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatDuration(track.duration), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'add_to_playlist', child: Text('Add to playlist')),
            ],
            onSelected: (v) {
              if (v == 'add_to_playlist') _showAddToPlaylist(context);
            },
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showAddToPlaylist(BuildContext context) {
    final playlists = context.read<PlaylistProvider>().playlists;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Add to playlist', style: Theme.of(ctx).textTheme.titleMedium),
          ),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No playlists yet. Create one in the Playlists tab.'),
            )
          else
            ...playlists.map((pl) => ListTile(
                  title: Text(pl.name),
                  subtitle: Text('${pl.trackPaths.length} tracks'),
                  onTap: () {
                    context.read<PlaylistProvider>().addTrack(pl.id, track.filePath);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to ${pl.name}')),
                    );
                  },
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
