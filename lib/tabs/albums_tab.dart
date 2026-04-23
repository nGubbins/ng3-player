import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../screens/album_detail_screen.dart';
import '../widgets/album_art.dart';

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  final _search = TextEditingController();
  AlbumSort _sort = AlbumSort.nameAZ;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Track>>> _sorted(Map<String, List<Track>> albumMap) {
    final q = _search.text.toLowerCase();
    var entries = albumMap.entries.where((e) =>
        q.isEmpty ||
        e.key.toLowerCase().contains(q) ||
        e.value.first.albumArtist.toLowerCase().contains(q)).toList();

    entries.sort((a, b) {
      switch (_sort) {
        case AlbumSort.nameAZ:
          return a.key.compareTo(b.key);
        case AlbumSort.artistAZ:
          return a.value.first.albumArtist.compareTo(b.value.first.albumArtist);
        case AlbumSort.yearNewest:
          return (b.value.first.year ?? 0).compareTo(a.value.first.year ?? 0);
        case AlbumSort.yearOldest:
          return (a.value.first.year ?? 0).compareTo(b.value.first.year ?? 0);
        case AlbumSort.trackCountDesc:
          return b.value.length.compareTo(a.value.length);
      }
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final albums = _sorted(library.albumMap);

    return Column(
      children: [
        _AlbumSearchSortBar(
          controller: _search,
          onChanged: (_) => setState(() {}),
          sort: _sort,
          onSortChanged: (v) { if (v != null) setState(() => _sort = v); },
        ),
        Expanded(
          child: albums.isEmpty
              ? Center(child: Text('No albums found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (_, i) {
                    final entry = albums[i];
                    final tracks = entry.value;
                    final art = tracks.map((t) => t.albumArt).firstWhere((a) => a != null, orElse: () => null);
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AlbumDetailScreen(albumName: entry.key, tracks: tracks))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AlbumArt(data: art, size: double.infinity, borderRadius: 8),
                          ),
                          const SizedBox(height: 6),
                          Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(tracks.first.albumArtist, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AlbumSearchSortBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AlbumSort sort;
  final ValueChanged<AlbumSort?> onSortChanged;

  const _AlbumSearchSortBar({
    required this.controller,
    required this.onChanged,
    required this.sort,
    required this.onSortChanged,
  });

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
                hintText: 'Search albums…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { controller.clear(); onChanged(''); })
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<AlbumSort>(
            value: sort,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: AlbumSort.nameAZ, child: Text('Name A–Z')),
              DropdownMenuItem(value: AlbumSort.artistAZ, child: Text('Artist A–Z')),
              DropdownMenuItem(value: AlbumSort.yearNewest, child: Text('Newest')),
              DropdownMenuItem(value: AlbumSort.yearOldest, child: Text('Oldest')),
              DropdownMenuItem(value: AlbumSort.trackCountDesc, child: Text('Most tracks')),
            ],
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

// Expose play-album helper used by AlbumDetailScreen
void playAlbum(BuildContext context, List<Track> tracks, int startIndex) {
  final sorted = List.of(tracks)
    ..sort((a, b) => (a.trackNumber ?? 999).compareTo(b.trackNumber ?? 999));
  context.read<PlayerProvider>().playQueue(sorted, startIndex);
}
