import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../screens/genre_detail_screen.dart';

class GenresTab extends StatefulWidget {
  const GenresTab({super.key});

  @override
  State<GenresTab> createState() => _GenresTabState();
}

class _GenresTabState extends State<GenresTab> {
  final _search = TextEditingController();
  GenreSort _sort = GenreSort.nameAZ;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Track>>> _sorted(Map<String, List<Track>> genreMap) {
    final q = _search.text.toLowerCase();
    var entries = genreMap.entries.where((e) => q.isEmpty || e.key.toLowerCase().contains(q)).toList();
    entries.sort((a, b) => _sort == GenreSort.nameAZ
        ? a.key.compareTo(b.key)
        : b.value.length.compareTo(a.value.length));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final genres = _sorted(library.genreMap);
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
                    hintText: 'Search genres…',
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
              DropdownButton<GenreSort>(
                value: _sort,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: GenreSort.nameAZ, child: Text('Name A–Z')),
                  DropdownMenuItem(value: GenreSort.trackCountDesc, child: Text('Most tracks')),
                ],
                onChanged: (v) { if (v != null) setState(() => _sort = v); },
              ),
            ],
          ),
        ),
        Expanded(
          child: genres.isEmpty
              ? Center(child: Text('No genres found', style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: genres.length,
                  itemBuilder: (_, i) {
                    final entry = genres[i];
                    return ListTile(
                      leading: Icon(Icons.label_outline, color: scheme.primary),
                      title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${entry.value.length} track${entry.value.length == 1 ? '' : 's'}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => GenreDetailScreen(genre: entry.key, tracks: entry.value))),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
