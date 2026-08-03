import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/document_factory/data/repositories/document_factory_repository_impl.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/shared_preferences_document_factory_store.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';

final documentFactoryRepositoryProvider = Provider<DocumentFactoryRepository>((
  ref,
) {
  return DocumentFactoryRepositoryImpl(
    preferencesStore: SharedPreferencesDocumentFactoryStore(),
  );
});
