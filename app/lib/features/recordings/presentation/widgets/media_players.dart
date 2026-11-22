import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/domain/media_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/recording_detail.dart';

/// Lets tests replace the real players, which need platform plugins.
typedef MediaPlayerBuilder = Widget Function(BuildContext context, MediaRevision revision);

Widget defaultMediaPlayerBuilder(BuildContext context, MediaRevision revision) => switch (revision
    .mediaType) {
  MediaType.audio => AudioPlayerView(key: ValueKey<Uri>(revision.url), url: revision.url),
  MediaType.video => VideoPlayerView(key: ValueKey<Uri>(revision.url), url: revision.url),
};

/// Audio with play/pause and a seek bar. The State only owns the player resource;
/// what is shown comes straight from the player's streams.
class AudioPlayerView extends StatefulWidget {
  const AudioPlayerView({required this.url, super.key});

  final Uri url;

  @override
  State<AudioPlayerView> createState() => _AudioPlayerViewState();
}

class _AudioPlayerViewState extends State<AudioPlayerView> {
  final AudioPlayer _player = AudioPlayer();
  late final Future<Duration?> _loading = _player.setUrl(widget.url.toString());

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return FutureBuilder<Duration?>(
      future: _loading,
      builder: (BuildContext context, AsyncSnapshot<Duration?> loaded) {
        if (loaded.hasError) {
          return _PlayerError(message: l10n.playerError);
        }
        return StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (BuildContext context, AsyncSnapshot<PlayerState> playerState) {
            final bool playing = playerState.data?.playing ?? false;
            final bool ready = loaded.connectionState == ConnectionState.done;
            return Row(
              children: <Widget>[
                IconButton.filled(
                  iconSize: 32,
                  tooltip: playing ? l10n.pause : l10n.play,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: !ready ? null : (playing ? _player.pause : _player.play),
                ),
                Expanded(child: _SeekBar(player: _player)),
              ],
            );
          },
        );
      },
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration>(
    stream: player.positionStream,
    builder: (BuildContext context, AsyncSnapshot<Duration> position) {
      final Duration total = player.duration ?? Duration.zero;
      final Duration current = position.data ?? Duration.zero;
      final double max = total.inMilliseconds.toDouble();
      return Row(
        children: <Widget>[
          Expanded(
            child: Slider(
              max: max <= 0 ? 1 : max,
              value: current.inMilliseconds.clamp(0, max <= 0 ? 0 : max).toDouble(),
              onChanged:
                  max <= 0
                      ? null
                      : (double value) => player.seek(Duration(milliseconds: value.round())),
            ),
          ),
          Text('${formatDuration(current)} / ${formatDuration(total)}'),
        ],
      );
    },
  );
}

String formatDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({required this.url, super.key});

  final Uri url;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(widget.url);
  late final Future<void> _initialising = _controller.initialize();

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return FutureBuilder<void>(
      future: _initialising,
      builder: (BuildContext context, AsyncSnapshot<void> initialised) {
        if (initialised.hasError) {
          return _PlayerError(message: l10n.playerError);
        }
        if (initialised.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder:
              (BuildContext context, VideoPlayerValue value, _) => Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        VideoPlayer(_controller),
                        IconButton.filled(
                          iconSize: 40,
                          tooltip: value.isPlaying ? l10n.pause : l10n.play,
                          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: value.isPlaying ? _controller.pause : _controller.play,
                        ),
                      ],
                    ),
                  ),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
        );
      },
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
    title: Text(message),
  );
}
