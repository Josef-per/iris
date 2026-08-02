import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final projectRoot = _findProjectRoot();

  test('nao declara .env como asset Flutter', () {
    final pubspec = File('${projectRoot.path}/pubspec.yaml').readAsStringSync();

    expect(
      RegExp(r'^\s*-\s*\.env\s*$', multiLine: true).hasMatch(pubspec),
      isFalse,
      reason: 'O arquivo .env nunca deve ser declarado como asset.',
    );
    expect(
      pubspec.contains('flutter_dotenv'),
      isFalse,
      reason: 'O cliente deve receber somente configuração publicável.',
    );
  });

  test('nao deixa identificadores de chave administrativa no cliente', () {
    const forbiddenMarkers = <String>[
      'SUPABASE_SECRET_KEY',
      'SUPABASE_SERVICE_ROLE_KEY',
      'SERVICE_ROLE_KEY',
      'sb_secret_',
      'service_role',
    ];
    final violations = <String>[];

    for (final directoryName in const [
      'lib',
      'web',
      'assets',
      'android',
      'ios',
      'macos',
      'linux',
      'windows',
    ]) {
      final directory = Directory('${projectRoot.path}/$directoryName');
      if (!directory.existsSync()) {
        continue;
      }

      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File ||
            _basename(entity.path) == '.env' ||
            !_isTextFile(entity.path)) {
          continue;
        }

        final contents = entity.readAsStringSync();
        final relativePath = _relativePath(projectRoot, entity);
        for (final marker in forbiddenMarkers) {
          if (contents.toLowerCase().contains(marker.toLowerCase())) {
            // Reporta somente caminho e marcador; nunca o valor encontrado.
            violations.add('$relativePath: $marker');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Chaves administrativas pertencem somente ao servidor.',
    );
  });

  test('build nao contem .env nem marcador de chave administrativa', () {
    final buildDirectory = Directory('${projectRoot.path}/build');
    if (!buildDirectory.existsSync()) {
      return;
    }

    const forbiddenMarkers = <String>[
      'SUPABASE_SECRET_KEY',
      'SUPABASE_SERVICE_ROLE_KEY',
      'SERVICE_ROLE_KEY',
      'sb_secret_',
    ];
    final exposedFiles = <String>[];
    final exposedMarkers = <String>[];

    for (final entity in buildDirectory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final relativePath = _relativePath(projectRoot, entity);
      if (_basename(entity.path) == '.env') {
        // A existência já é uma falha. Não leia o conteúdo deste arquivo.
        exposedFiles.add(relativePath);
        continue;
      }

      if (!_isTextFile(entity.path)) {
        continue;
      }

      final contents = entity.readAsStringSync();
      for (final marker in forbiddenMarkers) {
        if (contents.toLowerCase().contains(marker.toLowerCase())) {
          exposedMarkers.add('$relativePath: $marker');
        }
      }
    }

    expect(
      exposedFiles,
      isEmpty,
      reason: 'Remova artefatos antigos e gere o build novamente.',
    );
    expect(
      exposedMarkers,
      isEmpty,
      reason: 'O build cliente contém um marcador de chave administrativa.',
    );
  });

  test('migrations bloqueiam escalacao de papel no cliente', () {
    final rlsMigration = File(
      '${projectRoot.path}/supabase/migrations/'
      '0005_patient_professional_link_rls.sql',
    ).readAsStringSync();
    final backendMigration = File(
      '${projectRoot.path}/supabase/migrations/'
      '0006_professional_backend.sql',
    ).readAsStringSync();

    expect(
      rlsMigration.toLowerCase(),
      isNot(contains('create policy iris_usuarios_update_own')),
    );
    expect(
      rlsMigration.toLowerCase(),
      isNot(contains('create policy iris_profissionais_select_authenticated')),
    );
    expect(
      backendMigration.toLowerCase(),
      contains(
        'revoke insert, update, delete on public.usuarios '
        'from authenticated',
      ),
    );
    expect(backendMigration.toLowerCase(), contains('to service_role'));
  });

  test('convite QR persiste hash e aplica expiracao de forma atomica', () {
    final migration = File(
      '${projectRoot.path}/supabase/migrations/'
      '0006_professional_backend.sql',
    ).readAsStringSync().toLowerCase();

    expect(
      migration,
      contains('set search_path = pg_catalog, extensions, public'),
    );
    expect(migration, contains('gen_random_bytes(32)'));
    expect(migration, contains('digest(v_token'));
    expect(migration, contains('token_hash text not null unique'));
    expect(migration, contains('convite.expira_em > now()'));
    expect(migration, contains('for update of convite'));
    expect(migration, contains('autorizacao_status = \'revogado\''));
  });

  test('edicao profissional do paciente altera somente o vinculo', () {
    final migration = File(
      '${projectRoot.path}/supabase/migrations/'
      '0006_professional_backend.sql',
    ).readAsStringSync();
    final function = RegExp(
      r'create or replace function public\.iris_update_linked_patient\('
      r'([\s\S]*?)\$\$;',
      caseSensitive: false,
    ).firstMatch(migration);

    expect(function, isNotNull);
    final body = function!.group(0)!.toLowerCase();
    expect(body, contains('p_link_id uuid'));
    expect(body, contains('public.iris_professional_manages_link(p_link_id)'));
    expect(body, contains('update public.paciente_profissional'));
    expect(body, isNot(contains('update public.pacientes')));
    expect(body, isNot(contains('autorizacao_status =')));
  });
}

Directory _findProjectRoot() {
  var directory = Directory.current.absolute;

  while (true) {
    if (File('${directory.path}/pubspec.yaml').existsSync()) {
      return directory;
    }

    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Raiz do projeto Flutter não encontrada.');
    }
    directory = parent;
  }
}

bool _isTextFile(String path) {
  return const [
    '.dart',
    '.gradle',
    '.h',
    '.html',
    '.java',
    '.js',
    '.json',
    '.kt',
    '.kts',
    '.m',
    '.map',
    '.mm',
    '.plist',
    '.properties',
    '.swift',
    '.txt',
    '.xcconfig',
    '.xml',
    '.yaml',
    '.yml',
  ].any((extension) => path.toLowerCase().endsWith(extension));
}

String _relativePath(Directory root, FileSystemEntity entity) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  if (entity.path.startsWith(prefix)) {
    return entity.path.substring(prefix.length);
  }
  return entity.path;
}

String _basename(String path) {
  return path.split(Platform.pathSeparator).last;
}
