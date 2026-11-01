import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import 'local_image_stub.dart' if (dart.library.io) 'local_image_io.dart';

/// Image d'une photo de réclamation : data URL, URL http ou fichier local.
ImageProvider? complaintImageProvider(String path) {
  if (path.startsWith('data:image')) {
    final comma = path.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(path.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
  if (path.startsWith('http')) return NetworkImage(path);
  return localFileImage(path);
}

/// Ouvre la galerie plein écran sur la photo [initialIndex].
Future<void> openComplaintGallery(
  BuildContext context,
  List<String> paths, {
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          ComplaintPhotoGallery(paths: paths, initialIndex: initialIndex),
    ),
  );
}

/// Miniature carrée. Par défaut, un appui ouvre la photo en plein écran ;
/// [onTap] permet d'ouvrir la galerie complète. [onRemove] affiche une
/// croix de suppression (formulaire).
class ComplaintPhotoThumb extends StatelessWidget {
  const ComplaintPhotoThumb({
    super.key,
    required this.path,
    this.size = 84,
    this.onTap,
    this.onRemove,
  });

  final String path;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final image = complaintImageProvider(path);
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(color: context.cs.outlineVariant),
      ),
      child: Icon(Icons.broken_image_outlined, color: context.cs.outline),
    );

    final thumb = image == null
        ? placeholder
        : InkWell(
            borderRadius: radius,
            onTap: onTap ?? () => openComplaintGallery(context, [path]),
            child: ClipRRect(
              borderRadius: radius,
              child: Image(
                image: ResizeImage(image, width: (size * 3).round()),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
            ),
          );

    if (onRemove == null) return thumb;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        thumb,
        PositionedDirectional(
          top: -6,
          end: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Tooltip(
                message: context.l10n.complaintPhotoRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plein écran : balayage entre les photos (PageView) et zoom
/// (InteractiveViewer, double appui pour réinitialiser).
class ComplaintPhotoGallery extends StatefulWidget {
  const ComplaintPhotoGallery({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  final List<String> paths;
  final int initialIndex;

  @override
  State<ComplaintPhotoGallery> createState() => _ComplaintPhotoGalleryState();
}

class _ComplaintPhotoGalleryState extends State<ComplaintPhotoGallery> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// Zoom en cours : on bloque le balayage pour pouvoir se déplacer dans
  /// l'image agrandie.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.paths.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: total > 1
            ? Text(context.l10n.complaintPhotoCounter(_index + 1, total))
            : null,
      ),
      body: PageView.builder(
        controller: _pages,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: total,
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemBuilder: (_, i) => _ZoomablePhoto(
          path: widget.paths[i],
          onZoomChanged: (z) {
            if (z != _zoomed) setState(() => _zoomed = z);
          },
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.path, required this.onZoomChanged});

  final String path;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = complaintImageProvider(widget.path);
    if (image == null) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }
    return GestureDetector(
      onDoubleTap: () {
        _controller.value = Matrix4.identity();
        widget.onZoomChanged(false);
      },
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) =>
            widget.onZoomChanged(_controller.value.getMaxScaleOnAxis() > 1.01),
        child: Center(
          child: Image(image: image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
