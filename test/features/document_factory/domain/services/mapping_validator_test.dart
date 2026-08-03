import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/document_factory/domain/validation/mapping_validator.dart';

void main() {
  const placeholders = ['Name', 'City'];
  const headers = ['Name', 'City', 'Amount'];

  group('MappingValidator', () {
    test('unmappedPlaceholders lists placeholders without a column', () {
      expect(
        MappingValidator.unmappedPlaceholders(placeholders, const {}),
        placeholders,
      );
      expect(
        MappingValidator.unmappedPlaceholders(placeholders, const {
          'Name': 'Name',
        }),
        ['City'],
      );
      // Empty string counts as unmapped.
      expect(
        MappingValidator.unmappedPlaceholders(placeholders, const {
          'Name': '',
          'City': 'City',
        }),
        ['Name'],
      );
    });

    test('isComplete requires every placeholder mapped', () {
      expect(
        MappingValidator.isComplete(placeholders, const {
          'Name': 'Name',
          'City': 'City',
        }),
        isTrue,
      );
      expect(
        MappingValidator.isComplete(placeholders, const {'Name': 'Name'}),
        isFalse,
      );
    });

    test('isComplete is false when there are no placeholders', () {
      expect(MappingValidator.isComplete(const [], const {}), isFalse);
    });

    test('unknownColumns finds assignments missing from the header row', () {
      expect(
        MappingValidator.unknownColumns(const {
          'Name': 'Name',
          'City': 'Removed',
        }, headers),
        ['Removed'],
      );
      expect(
        MappingValidator.unknownColumns(const {'Name': 'Name'}, headers),
        isEmpty,
      );
    });

    test('isSaveable rejects extra keys and unknown columns', () {
      expect(
        MappingValidator.isSaveable(placeholders, const {
          'Name': 'Name',
          'City': 'City',
        }, headers),
        isTrue,
      );
      // Extra key not in placeholders.
      expect(
        MappingValidator.isSaveable(placeholders, const {
          'Name': 'Name',
          'City': 'City',
          'Ghost': 'Amount',
        }, headers),
        isFalse,
      );
      // Column not in headers.
      expect(
        MappingValidator.isSaveable(placeholders, const {
          'Name': 'Name',
          'City': 'Removed',
        }, headers),
        isFalse,
      );
      // Incomplete.
      expect(
        MappingValidator.isSaveable(placeholders, const {
          'Name': 'Name',
        }, headers),
        isFalse,
      );
    });
  });
}
