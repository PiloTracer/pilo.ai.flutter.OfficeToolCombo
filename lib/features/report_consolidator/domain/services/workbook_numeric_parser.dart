/// Parses spreadsheet cell text into numeric values for merge footers.
abstract final class WorkbookNumericParser {
  static const _creditTokens = {'cr', 'credit', 'credito', 'crédito', 'c'};
  static const _debitTokens = {'dr', 'debit', 'debito', 'débito', 'd'};

  /// Parses a cell that should hold a numeric amount or count.
  static double? parseAmount(String? raw) {
    return _parse(raw, applySignHint: null)?.signedValue;
  }

  /// Parses with optional row-level DR/CR hint and column kind from the header.
  static double? parseForTotal({
    required String? raw,
    required ColumnTotalKind columnKind,
    String? rowDrCrHint,
  }) {
    final parsed = _parse(raw, applySignHint: rowDrCrHint);
    if (parsed == null) {
      return null;
    }

    final value = parsed.signedValue;
    switch (columnKind) {
      case ColumnTotalKind.credit:
        return value.abs();
      case ColumnTotalKind.debit:
        return value.abs();
      case ColumnTotalKind.count:
      case ColumnTotalKind.amount:
        if (parsed.explicitCredit) {
          return -value.abs();
        }
        if (parsed.explicitDebit) {
          return value.abs();
        }
        return value;
      case ColumnTotalKind.notTotalizable:
        return null;
    }
  }

  static bool looksNumeric(String? raw) {
    return parseAmount(raw) != null;
  }

  static bool isDrCrToken(String? raw) {
    if (raw == null) {
      return false;
    }
    final token = raw.trim().toLowerCase();
    return _creditTokens.contains(token) || _debitTokens.contains(token);
  }

  static bool isCreditToken(String? raw) {
    if (raw == null) {
      return false;
    }
    return _creditTokens.contains(raw.trim().toLowerCase());
  }

  static _ParsedNumeric? _parse(String? raw, {String? applySignHint}) {
    if (raw == null) {
      return null;
    }

    var text = raw.trim();
    if (text.isEmpty) {
      return null;
    }

    var explicitCredit = false;
    var explicitDebit = false;

    final hint = applySignHint?.trim().toLowerCase();
    if (hint != null && hint.isNotEmpty) {
      if (_creditTokens.contains(hint)) {
        explicitCredit = true;
      } else if (_debitTokens.contains(hint)) {
        explicitDebit = true;
      }
    }

    final trailingToken = RegExp(
      r'\s+(CR|DR|Credit|Debit|Credito|Crédito|Debito|Débito)\s*$',
      caseSensitive: false,
    );
    final trailingMatch = trailingToken.firstMatch(text);
    if (trailingMatch != null) {
      final token = trailingMatch.group(1)!.toLowerCase();
      text = text.substring(0, trailingMatch.start).trim();
      if (_creditTokens.contains(token) || token == 'credit') {
        explicitCredit = true;
      } else {
        explicitDebit = true;
      }
    }

    var negative = false;
    if (text.startsWith('(') && text.endsWith(')')) {
      negative = true;
      text = text.substring(1, text.length - 1).trim();
    }

    text = text.replaceAll(RegExp(r'[\$,€£¥₹]'), '');
    text = text.replaceAll(' ', '');

    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    } else if (text.startsWith('+')) {
      text = text.substring(1);
    }

    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll(',', '');
    } else if (text.contains(',') && !text.contains('.')) {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        text = '${parts[0]}.${parts[1]}';
      } else {
        text = text.replaceAll(',', '');
      }
    }

    final value = double.tryParse(text);
    if (value == null) {
      return null;
    }

    var signed = negative ? -value : value;
    if (explicitCredit && signed > 0) {
      signed = -signed;
    } else if (explicitDebit && signed < 0) {
      signed = signed.abs();
    }

    return _ParsedNumeric(
      signedValue: signed,
      explicitCredit: explicitCredit,
      explicitDebit: explicitDebit,
    );
  }
}

enum ColumnTotalKind { amount, count, credit, debit, notTotalizable }

class _ParsedNumeric {
  const _ParsedNumeric({
    required this.signedValue,
    required this.explicitCredit,
    required this.explicitDebit,
  });

  final double signedValue;
  final bool explicitCredit;
  final bool explicitDebit;
}

/// Classifies columns for footer totals using header labels and cell contents.
abstract final class WorkbookColumnClassifier {
  static final _countHeaderPattern = RegExp(
    r'(qty|quantity|count|units|cantidad|unidades|pieces|items)',
    caseSensitive: false,
  );
  static final _amountHeaderPattern = RegExp(
    r'(amount|total|price|cost|subtotal|net|line total|monto|importe|precio|value|sum)',
    caseSensitive: false,
  );
  static final _creditHeaderPattern = RegExp(
    r'^(credit|credits|credito|crédito|cr)$',
    caseSensitive: false,
  );
  static final _debitHeaderPattern = RegExp(
    r'^(debit|debits|debito|débito|dr)$',
    caseSensitive: false,
  );
  static final _drCrHeaderPattern = RegExp(
    r'(dr/?cr|debit/?credit|type|sign|dc|nature)',
    caseSensitive: false,
  );
  static final _textHeaderPattern = RegExp(
    r'(date|fecha|branch|sucursal|region|category|categor|sku|codigo|código|product|producto|name|nombre|description|descripcion|descripción|code)',
    caseSensitive: false,
  );

  static ColumnTotalKind classify({
    required List<String?>? header,
    required List<List<String?>> dataRows,
    required int columnIndex,
  }) {
    final headerLabel = columnIndex < (header?.length ?? 0)
        ? header![columnIndex]?.trim()
        : null;
    final normalizedHeader = headerLabel?.toLowerCase() ?? '';

    if (_creditHeaderPattern.hasMatch(normalizedHeader)) {
      return ColumnTotalKind.credit;
    }
    if (_debitHeaderPattern.hasMatch(normalizedHeader)) {
      return ColumnTotalKind.debit;
    }
    if (_drCrHeaderPattern.hasMatch(normalizedHeader)) {
      return ColumnTotalKind.notTotalizable;
    }

    final numericRatio = _numericRatio(dataRows, columnIndex);
    final headerSuggestsCount = _countHeaderPattern.hasMatch(normalizedHeader);
    final headerSuggestsAmount = _amountHeaderPattern.hasMatch(
      normalizedHeader,
    );
    final headerSuggestsText =
        normalizedHeader.isNotEmpty &&
        _textHeaderPattern.hasMatch(normalizedHeader);

    if (headerSuggestsCount &&
        (numericRatio >= 0.5 || _hasAnyNumeric(dataRows, columnIndex))) {
      return ColumnTotalKind.count;
    }

    if (headerSuggestsAmount &&
        (numericRatio >= 0.5 || _hasAnyNumeric(dataRows, columnIndex))) {
      return ColumnTotalKind.amount;
    }

    if (headerSuggestsText && numericRatio < 0.75) {
      return ColumnTotalKind.notTotalizable;
    }

    if (numericRatio >= 0.75 && _hasAnyNumeric(dataRows, columnIndex)) {
      if (headerSuggestsCount) {
        return ColumnTotalKind.count;
      }
      return ColumnTotalKind.amount;
    }

    if (!headerSuggestsText &&
        numericRatio >= 0.9 &&
        _hasAnyNumeric(dataRows, columnIndex)) {
      return ColumnTotalKind.amount;
    }

    return ColumnTotalKind.notTotalizable;
  }

  static int? findDrCrColumnIndex(List<String?>? header) {
    if (header == null) {
      return null;
    }
    for (var i = 0; i < header.length; i++) {
      final label = header[i]?.trim().toLowerCase() ?? '';
      if (_drCrHeaderPattern.hasMatch(label)) {
        return i;
      }
    }
    return null;
  }

  static bool isDuplicateHeaderRow(List<String?> row, List<String?>? header) {
    if (header == null || row.length != header.length) {
      return false;
    }
    for (var i = 0; i < header.length; i++) {
      final expected = header[i]?.trim().toLowerCase() ?? '';
      final actual = i < row.length ? row[i]?.trim().toLowerCase() ?? '' : '';
      if (expected != actual) {
        return false;
      }
    }
    return true;
  }

  static double _numericRatio(List<List<String?>> dataRows, int columnIndex) {
    var nonEmpty = 0;
    var numeric = 0;

    for (final row in dataRows) {
      if (columnIndex >= row.length) {
        continue;
      }
      final raw = row[columnIndex]?.trim();
      if (raw == null || raw.isEmpty) {
        continue;
      }
      nonEmpty++;
      if (WorkbookNumericParser.looksNumeric(raw)) {
        numeric++;
      }
    }

    if (nonEmpty == 0) {
      return 0;
    }
    return numeric / nonEmpty;
  }

  static bool _hasAnyNumeric(List<List<String?>> dataRows, int columnIndex) {
    for (final row in dataRows) {
      if (columnIndex >= row.length) {
        continue;
      }
      if (WorkbookNumericParser.looksNumeric(row[columnIndex])) {
        return true;
      }
    }
    return false;
  }
}
