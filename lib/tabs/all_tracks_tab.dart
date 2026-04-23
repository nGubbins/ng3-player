import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';

class AllTracksTab extends StatefulWidget {
  const AllTracksTab({super.key});

  @override
  State<AllTracksTab> createState() => _AllTracksTabState();
}

class _AllTracksTabState extends State<AllTracksTab> {
  final _search = TextEditingController();
  TrackSort _sort = TrackSort.titleAZ;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Track> _sorted(List<Track> tracks) {
    final q = _search.text.toLowerCase();
    final filtered = q.isEmpty
        ? tracks
        : tracks.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q)).toList();

    return filtered..sort((a, b) {
      switch (_sort) {
        case TrackSort.titleAZ:
          return a.title.compareTo(b.title);
        case TrackSort.titleZA:
          return b.title.compareTo(a.title);
        case TrackSort.artistAZ:
          return a.artist.compareTo(b.artist);
        case TrackSort.artistZA:
          return b.artist.compareTo(a.artist);
        case TrackSort.albumAZ:
          return a.album.compareTo(b.album);
        case TrackSort.durationAsc:
          return a.duration.compareTo(b.duration);
        case TrackSort.durationDesc:
          return b.duration.compareTo(a.duration);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();
    final sorted = _sorted(library.tracks);

    return Column(
      children: [
        _SearchSortBar(
          controller: _search,
          onChanged: (_) => setState(() {}),
          sortWidget: DropdownButton<TrackSort>(
            value: _sort,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: TrackSort.titleAZ, child: Text('Title A–Z')),
              DropdownMenuItem(value: TrackSort.titleZA, child: Text('Title Z–A')),
              DropdownMenuItem(value: TrackSort.artistAZ, child: Text('Artist A–Z')),
              DropdownMenuItem(value: TrackSort.artistZA, child: Text('Artist Z–A')),
              DropdownMenuItem(value: TrackSort.albumAZ, child: Text('Album A–Z')),
              DropdownMenuItem(value: TrackSort.durationAsc, child: Text('Shortest first')),
              DropdownMenuItem(value: TrackSort.durationDesc, child: Text('Longest first')),
            ],
            onChanged: (v) { if (v != null) setState(() => _sort = v); },
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final track = sorted[i];
                    return TrackTile(
                      track: track,
                      isPlaying: player.currentTrack?.filePath == track.filePath,
                      onTap: () => context.read<PlayerProvider>().playQueue(sorted, i),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchSortBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Widget sortWidget;

  const _SearchSortBar({required this.controller, required this.onChanged, required this.sortWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { controller.clear(); onChanged(''); },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          sortWidget,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No tracks found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
