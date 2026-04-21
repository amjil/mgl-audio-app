import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

DatabaseConnection _connect() {
  return DatabaseConnection.delayed(Future(() async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocsDir.path, 'offline_books_v1.sqlite');
    return NativeDatabase.createBackgroundConnection(File(dbPath));
  }));
}

class AudioCacheDatabase extends GeneratedDatabase {
  AudioCacheDatabase() : super(_connect());

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
}

Future<AudioCacheDatabase> initDriftDatabase() async {
  final db = AudioCacheDatabase();
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS offline_books (book_id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER NOT NULL)',
  );
  return db;
}
