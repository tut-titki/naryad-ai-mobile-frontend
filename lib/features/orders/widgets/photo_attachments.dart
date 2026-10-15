import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/ui.dart';

enum _PhotoSource { camera, gallery }

class PhotoAttachments extends StatelessWidget {
  const PhotoAttachments({
    super.key,
    required this.title,
    required this.photos,
    this.busy = false,
    this.onCamera,
    this.onGallery,
    this.onRemove,
    this.framed = true,
  });

  final String title;
  final List<OrderPhoto> photos;
  final bool busy;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final ValueChanged<int>? onRemove;
  final bool framed;

  Future<void> attachPhoto(BuildContext context) async {
    final s = strings(context);
    final source = await showAppBottomSheet<_PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                s.choosePhotoSource,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (onCamera != null)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(s.camera),
                onTap: () => Navigator.pop(context, _PhotoSource.camera),
              ),
            if (onGallery != null)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(s.gallery),
                onTap: () => Navigator.pop(context, _PhotoSource.gallery),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel),
              ),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (source) {
      case _PhotoSource.camera:
        onCamera?.call();
      case _PhotoSource.gallery:
        onGallery?.call();
      case null:
        break;
    }
  }

  void preview(BuildContext context, OrderPhoto photo) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              photo.name,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: .5,
              maxScale: 5,
              child: Image.memory(
                photo.bytes,
                errorBuilder: (_, _, _) => Text(
                  uiText(context, 'Не удалось открыть фото'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editable = onRemove != null;
    final canAdd = !busy && photos.length < 5;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                uiText(context, title),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            Text(
              uiText(
                context,
                editable ? '${photos.length}/5' : '${photos.length}',
              ),
              style: TextStyle(color: muted),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (photos.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 38,
                  color: muted,
                ),
                SizedBox(height: 8),
                Text(
                  uiText(context, 'Фото не прикреплены'),
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < photos.length; index++)
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Material(
                          child: InkWell(
                            onTap: () => preview(context, photos[index]),
                            child: Image.memory(
                              photos[index].bytes,
                              fit: BoxFit.cover,
                              cacheWidth: 360,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: background,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (editable)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: uiText(context, 'Удалить фото ${index + 1}'),
                          onPressed: busy ? null : () => onRemove!(index),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                          ),
                          icon: Icon(Icons.close, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (editable) ...[
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: canAdd && (onCamera != null || onGallery != null)
                ? () => attachPhoto(context)
                : null,
            icon: const Icon(Icons.attach_file),
            label: Text(strings(context).attachPhoto),
          ),
          if (busy)
            Padding(
              padding: EdgeInsets.only(top: 14),
              child: LinearProgressIndicator(),
            ),
        ],
      ],
    );
    return framed ? Panel(child: content) : content;
  }
}
