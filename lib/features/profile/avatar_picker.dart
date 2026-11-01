import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Résultat du choix de photo : nouvelle image ou suppression.
class AvatarChoice {
  const AvatarChoice.picked(String this.dataUrl);
  const AvatarChoice.removed() : dataUrl = null;

  /// `data:image/...;base64,...` (stocké tel quel dans users.avatar_url).
  final String? dataUrl;

  bool get isRemoved => dataUrl == null;
}

class AvatarPickException implements Exception {
  const AvatarPickException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum _Source { gallery, files, remove }

/// Feuille « Photo de profil » : Galerie, Fichiers, ou Supprimer.
/// Retourne `null` si l'utilisateur annule.
Future<AvatarChoice?> pickAvatar(
  BuildContext context, {
  required bool hasPhoto,
}) async {
  // Traductions lues avant les `await` (le context peut ensuite changer).
  final l = context.l10n;
  final source = await showModalBottomSheet<_Source>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.avatarSheetTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.cs.onSurface,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.accent,
            ),
            title: Text(l.avatarGallery),
            onTap: () => Navigator.pop(sheetContext, _Source.gallery),
          ),
          ListTile(
            leading: const Icon(
              Icons.folder_open_rounded,
              color: AppColors.accent,
            ),
            title: Text(l.avatarFiles),
            subtitle: Text(l.avatarFilesSubtitle),
            onTap: () => Navigator.pop(sheetContext, _Source.files),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: Text(
                l.avatarRemove,
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () => Navigator.pop(sheetContext, _Source.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  switch (source) {
    case null:
      return null;
    case _Source.remove:
      return const AvatarChoice.removed();
    case _Source.gallery:
    case _Source.files:
      break;
  }

  // Android : photo picker système (galerie) ou sélecteur de documents
  // (fichiers). Sans effet sur web / iOS.
  // Le réglage est global : on le remet ensuite pour ne pas changer le
  // comportement des autres écrans (ex. photos véhicule).
  final platform = ImagePickerPlatform.instance;
  final android = platform is ImagePickerAndroid ? platform : null;
  final previousMode = android?.useAndroidPhotoPicker;
  android?.useAndroidPhotoPicker = source == _Source.gallery;

  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
  } catch (_) {
    throw AvatarPickException(l.avatarOpenFailed);
  } finally {
    if (android != null && previousMode != null) {
      android.useAndroidPhotoPicker = previousMode;
    }
  }
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    throw AvatarPickException(l.avatarUnreadable);
  }
  // Image déjà réduite à 512 px : au-delà de 1,5 Mo, ce n'est pas une photo.
  if (bytes.length > 1.5 * 1024 * 1024) {
    throw AvatarPickException(l.avatarTooLarge);
  }

  final name = file.name.toLowerCase();
  final mime = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
      ? 'image/webp'
      : 'image/jpeg';
  return AvatarChoice.picked('data:$mime;base64,${base64Encode(bytes)}');
}
