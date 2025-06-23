// lib/features/home/models/quick_action.dart

import 'package:flutter/material.dart';

/// Model per le Quick Actions nella dashboard
class QuickAction {
  final String id;
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const QuickAction({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  /// Helper per creare una copia con parametri modificati
  QuickAction copyWith({
    String? id,
    IconData? icon,
    String? title,
    Color? color,
    VoidCallback? onTap,
    bool? isEnabled,
  }) {
    return QuickAction(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      color: color ?? this.color,
      onTap: onTap ?? this.onTap,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is QuickAction &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QuickAction(id: $id, title: $title, isEnabled: $isEnabled)';
}