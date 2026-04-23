import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../screens/artist_detail_screen.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({super.key});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final _search = TextEditingController();
  ArtistSort _sort = ArtistSort.nameAZ;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Track>>> _sorted(Map<String, List<Track>> artistMap) {
    final q = _search.text.toLowerCase();
    var entries = artistMap.entries.where((e) => q.isEmpty || e.key.toLowerCase().contains(q)).toList();
    entries.sort((a, b) {
      switch (_sort) {
        case ArtistSort.nameAZ:
          return a.key.compareTo(b.key);
        case ArtistSort.trackCountDesc:
          return b.value.length.compareTo(a.value.length);
        case ArtistSort.albumCountDesc:
          final aAlbums = a.value.map((t) => t.album).toSet().length;
          final bAlbums = b.value.map((t) => t.album).toSet().length;
          return bAlbums.compareTo(aAlbums);
      }
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final artists = _sorted(library.artistMap);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search artists…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _search.clear(); setState(() {}); })
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<ArtistSort>(
                value: _sort,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ArtistSort.nameAZ, child: Text('Name A–Z')),
                  DropdownMenuItem(value: ArtistSort.trackCountDesc, child: Text('Most tracks')),
                  DropdownMenuItem(value: ArtistSort.albumCountDesc, child: Text('Most albums')),
                ],
                onChanged: (v) { if (v != null) setState(() => _sort = v); },
              ),
            ],
          ),
        ),
        Expanded(
          child: artists.isEmpty
              ? Center(child: Text('No artists found', style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: artists.length,
                  itemBuilder: (_, i) {
                    final entry = artists[i];
                    final albumCount = entry.value.map((t) => t.album).toSet().length;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                            style: TextStyle(color: scheme.onPrimaryContainer)),
                      ),
                      title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('$albumCount album${albumCount == 1 ? '' : 's'} • ${entry.value.length} tracks',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ArtistDetailScreen(artistName: entry.key, tracks: entry.value))),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
