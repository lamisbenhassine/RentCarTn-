import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Photo de profil ronde : image `data:image/...;base64` ou URL réseau,
/// sinon les initiales.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 68,
    this.onDark = false,
  });

  final String initials;
  final String? avatarUrl;
  final double size;

  /// `true` sur fond navy (bordure et texte clairs).
  final bool onDark;

  /// Dernière image décodée : évite de décoder le base64 à chaque build.
  static String? _cachedUrl;
  static Uint8List? _cachedBytes;

  static Uint8List? _decode(String url) {
    if (url == _cachedUrl) return _cachedBytes;
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      _cachedBytes = base64Decode(url.substring(comma + 1));
      _cachedUrl = url;
      return _cachedBytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    Widget? image;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        final bytes = _decode(url);
        if (bytes != null) {
          image = Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        }
      } else if (url.startsWith('http')) {
        image = Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(),
        );
      }
    }

    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.25)
              : context.cs.outlineVariant,
          width: 2,
        ),
      ),
      child: image ?? _initials(),
    );
  }

  Widget _initials() => Center(
    child: Text(
      initials,
      style: TextStyle(
        color: onDark ? Colors.white : AppColors.accent,
        fontSize: size * 0.34,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
