import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../tabs/all_tracks_tab.dart';
import '../tabs/albums_tab.dart';
import '../tabs/artists_tab.dart';
import '../tabs/genres_tab.dart';
import '../tabs/playlists_tab.dart';
import '../widgets/now_playing_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _playerExpanded = false;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorSub = context.read<PlayerProvider>().errors.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ng3'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Choose music folder',
            onPressed: () => context.read<LibraryProvider>().pickAndLoad(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: () {
              final lib = context.read<LibraryProvider>();
              if (lib.libraryPath != null) lib.loadLibrary(lib.libraryPath!);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All tracks'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Genres'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            _buildBody(library),
            NowPlayingPanel(
              isExpanded: _playerExpanded,
              availableHeight: constraints.maxHeight,
              onToggle: () => setState(() => _playerExpanded = !_playerExpanded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LibraryProvider library) {
    if (library.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: library.loadProgress > 0 ? library.loadProgress : null),
            const SizedBox(height: 16),
            Text('Loading library… ${(library.loadProgress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      );
    }

    if (library.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Error: ${library.error}', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<LibraryProvider>().pickAndLoad(),
              child: const Text('Choose folder'),
            ),
          ],
        ),
      );
    }

    if (library.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No music library selected', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Choose a folder containing MP3 files',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.read<LibraryProvider>().pickAndLoad(),
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose music folder'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabs,
      children: const [
        AllTracksTab(),
        AlbumsTab(),
        ArtistsTab(),
        GenresTab(),
        PlaylistsTab(),
      ],
    );
  }
}
