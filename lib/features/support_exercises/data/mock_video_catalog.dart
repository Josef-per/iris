/// Vídeo-aula fictícia do protótipo.
///
/// Autor e revisor são identificados como demonstração; a data de revisão é
/// fictícia. A transcrição é escrita pela equipe do protótipo.
class SupportVideo {
  const SupportVideo({
    required this.id,
    required this.title,
    required this.theme,
    required this.durationMinutes,
    required this.author,
    required this.reviewer,
    required this.reviewedOn,
    required this.transcript,
  });

  final String id;
  final String title;
  final String theme;
  final int durationMinutes;
  final String author;
  final String reviewer;
  final String reviewedOn;

  /// Transcrição fictícia exibida como alternativa textual.
  final String transcript;
}

/// Biblioteca fictícia de vídeos do protótipo.
///
/// O vídeo nunca começa sozinho e o conteúdo é claramente demonstração.
abstract final class MockVideoCatalog {
  static const List<SupportVideo> videos = <SupportVideo>[
    SupportVideo(
      id: 'video-return-present',
      title: 'Como voltar ao presente',
      theme: 'Aterrar com os sentidos',
      durationMinutes: 3,
      author: 'Equipe de conteúdo Íris (demonstração)',
      reviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      reviewedOn: '10/03/2027',
      transcript:
          'Quando o momento parece pesado, você pode voltar ao presente '
          'com os sentidos. Olhe ao redor e escolha três coisas que você '
          'vê. Escute os sons próximos e distantes. Sinta o contato dos '
          'pés com o chão. Não precisa fazer nada com o que percebeu — '
          'apenas notar já ajuda a criar espaço.',
    ),
    SupportVideo(
      id: 'video-thoughts-orders',
      title: 'Pensamentos não são ordens',
      theme: 'Distância de pensamentos difíceis',
      durationMinutes: 4,
      author: 'Equipe de conteúdo Íris (demonstração)',
      reviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      reviewedOn: '10/03/2027',
      transcript:
          'Um pensamento difícil não é uma ordem e não é um fato. Você '
          'pode notá-lo e nomeá-lo: “estou tendo o pensamento de que…” — '
          'e perceber que quem observa o pensamento é maior do que ele. '
          'Escolha uma ação pequena e siga com ela, sem discutir se o '
          'pensamento é verdadeiro.',
    ),
    SupportVideo(
      id: 'video-kindness-hard',
      title: 'Gentileza em momentos difíceis',
      theme: 'Autocompaixão',
      durationMinutes: 5,
      author: 'Equipe de conteúdo Íris (demonstração)',
      reviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      reviewedOn: '10/03/2027',
      transcript:
          'Em momentos difíceis, muitas pessoas são gentis com os outros '
          'e duras consigo mesmas. Tente dizer a você o que diria a '
          'alguém querido: “isso é difícil, e você está tentando”. '
          'Gentileza consigo também é prática — e pode ser treinada em '
          'pequenas doses, sem pressa.',
    ),
  ];

  static SupportVideo? byId(String id) {
    for (final video in videos) {
      if (video.id == id) return video;
    }
    return null;
  }
}