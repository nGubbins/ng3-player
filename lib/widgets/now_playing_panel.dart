import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/player_provider.dart';
import '../utils/format_utils.dart';
import 'album_art.dart';

class NowPlayingPanel extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const NowPlayingPanel({super.key, required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isExpanded ? screenHeight : 72,
        child: Material(
          elevation: 16,
          color: scheme.surface,
          child: isExpanded
              ? _FullPlayer(player: player, onMinimize: onToggle)
              : _MiniPlayer(player: player, onExpand: onToggle),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final PlayerProvider player;
  final VoidCallback onExpand;

  const _MiniPlayer({required this.player, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final track = player.currentTrack!;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            AlbumArt(data: track.albumArt, size: 48, borderRadius: 6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              onPressed: player.skipPrevious,
              icon: const Icon(Icons.skip_previous),
              tooltip: 'Previous',
            ),
            IconButton(
              onPressed: player.playPause,
              icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
              tooltip: player.isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              onPressed: player.skipNext,
              icon: const Icon(Icons.skip_next),
              tooltip: 'Next',
            ),
          ],
        ),
      ),
    );
  }
}

class _FullPlayer extends StatelessWidget {
  final PlayerProvider player;
  final VoidCallback onMinimize;

  const _FullPlayer({required this.player, required this.onMinimize});

  @override
  Widget build(BuildContext context) {
    final track = player.currentTrack!;
    final scheme = Theme.of(context).colorScheme;
    final isPlaying = player.isPlaying;
    final pos = player.position;
    final dur = player.duration;
    final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final curMs = pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble();

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onMinimize,
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Minimise',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AlbumArt(data: track.albumArt, size: 240, borderRadius: 12),
                  const SizedBox(height: 32),
                  Text(track.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${track.artist} • ${track.album}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 24),

                  // Seek bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: curMs,
                      max: maxMs,
                      onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(pos), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        Text(formatDuration(dur), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transport controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(onPressed: player.skipPrevious, icon: const Icon(Icons.skip_previous), iconSize: 36),
                      IconButton(onPressed: player.seekBack, icon: const Icon(Icons.replay_10), iconSize: 36),
                      Container(
                        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: player.playPause,
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: scheme.onPrimary),
                          iconSize: 40,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      IconButton(onPressed: player.seekForward, icon: const Icon(Icons.forward_10), iconSize: 36),
                      IconButton(onPressed: player.skipNext, icon: const Icon(Icons.skip_next), iconSize: 36),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ModeButton(
                        icon: Icons.shuffle,
                        active: player.mode == PlaybackMode.shuffle,
                        tooltip: 'Shuffle',
                        onTap: () => player.setMode(
                          player.mode == PlaybackMode.shuffle ? PlaybackMode.regular : PlaybackMode.shuffle,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _ModeButton(
                        icon: _repeatIcon(player.mode),
                        active: player.mode == PlaybackMode.repeatOne || player.mode == PlaybackMode.repeatAll,
                        tooltip: _repeatLabel(player.mode),
                        onTap: () => player.setMode(_nextRepeatMode(player.mode)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _repeatIcon(PlaybackMode mode) {
    return mode == PlaybackMode.repeatOne ? Icons.repeat_one : Icons.repeat;
  }

  String _repeatLabel(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.repeatAll:
        return 'Repeat all';
      case PlaybackMode.repeatOne:
        return 'Repeat one';
      default:
        return 'Repeat off';
    }
  }

  PlaybackMode _nextRepeatMode(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.regular:
      case PlaybackMode.shuffle:
        return PlaybackMode.repeatAll;
      case PlaybackMode.repeatAll:
        return PlaybackMode.repeatOne;
      case PlaybackMode.repeatOne:
        return player.mode == PlaybackMode.shuffle ? PlaybackMode.shuffle : PlaybackMode.regular;
    }
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _ModeButton({required this.icon, required this.active, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
