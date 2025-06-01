// lib/core/extensions/string_extensions.dart
extension StringExtensions on String {
  bool get isEmail {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(this);
  }

  bool get isUsername {
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(this);
  }

  bool get isValidName {
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(this);
  }

  bool get isNumeric {
    return RegExp(r'^\d+$').hasMatch(this);
  }

  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.isEmpty ? word : word.capitalize).join(' ');
  }

  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + '...';
  }

  String get removeSpaces {
    return replaceAll(' ', '');
  }

  String get removeSpecialChars {
    return replaceAll(RegExp(r'[^\w\s]'), '');
  }

  bool get isNotEmpty {
    return trim().isNotEmpty;
  }

  bool get isBlank {
    return trim().isEmpty;
  }

  String? get nullIfEmpty {
    return isEmpty ? null : this;
  }
}