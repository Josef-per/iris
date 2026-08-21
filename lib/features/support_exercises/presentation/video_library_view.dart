import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/data/mock_video_catalog.dart';

/// Biblioteca de vídeos e player fictício.
///
/// O vídeo nunca começa sozinho. O player oferece legenda, transcrição,
/// velocidade, pausar e alternativa somente em texto.
class VideoLibraryView extends StatefulWidget {
  const VideoLibraryView({
    super.key,
    required this.onExit,
    this.initialVideo,
  });

  /// Sai da biblioteca (volta ao fluxo anterior).
  final VoidCallback onExit;

  /// Vídeo aberto diretamente (ex.: vindo de uma recomendação).
  final SupportVideo? initialVideo;

  @override
  State<VideoLibraryView> createState() => _VideoLibraryViewState();
}

class _VideoLibraryViewState extends State<VideoLibraryView> {
  SupportVideo? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialVideo;
  }

  @override
  Widget build(BuildContext context) {
    final video = _selected;
    if (video != null) {
      return _MockVideoPlayer(
        key: ValueKey(video.id),
        video: video,
        onBack: () => setState(() => _selected = null),
      );
    }
    return _VideoLibraryList(
      videos: MockVideoCatalog.videos,
      onBack: widget.onExit,
      onOpen: (video) => setState(() => _selected = video),
    );
  }
}

class _VideoLibraryList extends StatelessWidget {
  const _VideoLibraryList({
    required this.videos,
    required this.onBack,
    required this.onOpen,
  });

  final List<SupportVideo> videos;
  final VoidCallback onBack;
  final ValueChanged<SupportVideo> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          key: const Key('video-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar'),
        ),
        const SizedBox(height: 4),
        Text('Biblioteca de vídeos', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Vídeos curtos com legenda e transcrição. Eles nunca começam '
          'sozinhos.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              button: true,
              label:
                  '${video.title}. ${video.theme}. '
                  '${video.durationMinutes} minutos.',
              child: Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: InkWell(
                  key: Key('video-card-${video.id}'),
                  onTap: () => onOpen(video),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${video.durationMinutes} min · '
                                '${video.theme}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Demonstração — revisado em '
                                '${video.reviewedOn}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Conteúdo fictício de demonstração: autor e revisor são fictícios '
          'e nenhum vídeo real é reproduzido.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MockVideoPlayer extends StatefulWidget {
  const _MockVideoPlayer({
    super.key,
    required this.video,
    required this.onBack,
  });

  final SupportVideo video;
  final VoidCallback onBack;

  @override
  State<_MockVideoPlayer> createState() => _MockVideoPlayerState();
}

class _MockVideoPlayerState extends State<_MockVideoPlayer> {
  bool _playing = false;
  bool _captionsOn = false;
  bool _showTranscript = false;
  bool _showTextAlternative = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          key: const Key('video-back-to-library'),
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar para a biblioteca'),
        ),
        const SizedBox(height: 12),
        Text(video.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${video.durationMinutes} min · ${video.theme}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: _showTextAlternative
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Modo texto: use a transcrição abaixo.',
                    style: TextStyle(color: AppColors.white),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const Key('video-play-toggle'),
                      tooltip: _playing ? 'Pausar' : 'Reproduzir',
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(56),
                        foregroundColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(alpha: .14),
                      ),
                      onPressed: () => setState(() => _playing = !_playing),
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _playing
                          ? 'Reproduzindo (demonstração)…'
                          : 'Pronto para reproduzir — toque para começar.',
                      style: const TextStyle(color: AppColors.white),
                    ),
                    if (_captionsOn) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Legenda (fictícia): ${video.title}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.lavender),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilterChip(
              key: const Key('video-captions'),
              label: const Text('Legenda'),
              selected: _captionsOn,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (value) => setState(() => _captionsOn = value),
            ),
            FilterChip(
              key: const Key('video-transcript'),
              label: const Text('Transcrição'),
              selected: _showTranscript,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (value) =>
                  setState(() => _showTranscript = value),
            ),
            FilterChip(
              key: const Key('video-text-mode'),
              label: const Text('Ver como texto'),
              selected: _showTextAlternative,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (value) =>
                  setState(() => _showTextAlternative = value),
            ),
            DropdownMenu<double>(
              key: const Key('video-speed'),
              label: const Text('Velocidade'),
              initialSelection: 1,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 1, label: '1x'),
                DropdownMenuEntry(value: 1.25, label: '1,25x'),
                DropdownMenuEntry(value: 1.5, label: '1,5x'),
                DropdownMenuEntry(value: 2, label: '2x'),
              ],
            ),
          ],
        ),
        if (_showTranscript || _showTextAlternative) ...[
          const SizedBox(height: 16),
          Container(
            key: const Key('video-transcript-content'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              video.transcript,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Autor e revisor (demonstração): ${video.author} · '
          '${video.reviewer}. Revisão em ${video.reviewedOn}. Nenhum vídeo '
          'real é reproduzido.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}