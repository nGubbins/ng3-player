import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';
import 'album_detail_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;
  final List<Track> tracks;

  const ArtistDetailScreen({super.key, required this.artistName, required this.tracks});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  bool _showTracks = false;

  Map<String, List<Track>> get _albums {
    final m = <String, List<Track>>{};
    for (final t in widget.tracks) {
      m.putIfAbsent(t.album, () => []).add(t);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final albums = _albums;
    final allSorted = List.of(widget.tracks)..sort((a, b) => a.title.compareTo(b.title));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
        actions: [
          FilledButton.icon(
            onPressed: () => context.read<PlayerProvider>().playQueue(allSorted, 0),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Play all'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Albums section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Albums', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
          ),
          ...albums.entries.map((entry) {
            final albumTracks = List.of(entry.value)
              ..sort((a, b) => (a.trackNumber ?? 999).compareTo(b.trackNumber ?? 999));
            final art = albumTracks.map((t) => t.albumArt).firstWhere((a) => a != null, orElse: () => null);
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: art != null
                      ? Image.memory(art, fit: BoxFit.cover)
                      : Container(color: scheme.surfaceContainerHigh, child: Icon(Icons.album, color: scheme.onSurfaceVariant)),
                ),
              ),
              title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${albumTracks.length} track${albumTracks.length == 1 ? '' : 's'}${albumTracks.first.year != null ? ' • ${albumTracks.first.year}' : ''}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AlbumDetailScreen(albumName: entry.key, tracks: albumTracks))),
            );
          }),

          // Tracks section toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () => setState(() => _showTracks = !_showTracks),
              child: Row(
                children: [
                  Text('All tracks (${widget.tracks.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
                  Icon(_showTracks ? Icons.expand_less : Icons.expand_more, color: scheme.primary),
                ],
              ),
            ),
          ),
          if (_showTracks)
            ...allSorted.map((t) => TrackTile(
                  track: t,
                  isPlaying: player.currentTrack?.filePath == t.filePath,
                  onTap: () => context.read<PlayerProvider>().playQueue(allSorted, allSorted.indexOf(t)),
                )),
        ],
      ),
    );
  }
}
