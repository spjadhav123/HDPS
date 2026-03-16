// lib/features/gallery/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/gallery_model.dart';
import '../../core/providers/gallery_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/app_card.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../shared/widgets/app_animations.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(galleryAlbumsProvider);
    final auth = ref.watch(authProvider);
    final isAdmin = auth.user?.role == 'admin' || auth.user?.role == 'teacher';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PageHeader(
              title: 'School Gallery (${albumsAsync.value?.length ?? 0} Albums)',
              subtitle: 'Memories and activities captured in photos',
              action: isAdmin
                  ? ElevatedButton.icon(
                      onPressed: () => _showAddAlbumDialog(context, ref),
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: const Text('New Album'),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) {
                    return EmptyState(
                      emoji: '📸',
                      title: 'No albums yet',
                      subtitle: 'School photos and event memories will appear here.',
                      actionLabel: isAdmin ? 'Create First Album' : null,
                      onAction: isAdmin ? () => _showAddAlbumDialog(context, ref) : null,
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (ctx, i) => _AlbumCard(album: albums[i]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAlbumDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Album Title')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              final album = GalleryAlbum(
                id: '',
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                coverUrl: '',
                photoCount: 0,
                createdAt: DateTime.now(),
              );
              final id = await ref.read(galleryRepositoryProvider).createAlbum(album);
              Navigator.pop(ctx);
              
              // Construct a realistic object to navigate to
              final newAlbum = GalleryAlbum(
                id: id,
                title: album.title,
                description: album.description,
                coverUrl: '',
                photoCount: 0,
                createdAt: DateTime.now(),
              );
              
              if (ctx.mounted) {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => AlbumDetailsScreen(album: newAlbum)),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  final GalleryAlbum album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.user?.role == 'admin' || auth.user?.role == 'teacher';

    return Stack(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlbumDetailsScreen(album: album)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: album.coverUrl.isEmpty
                      ? Container(
                          color: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.image_rounded, color: AppTheme.primary, size: 40),
                        )
                      : Image.network(
                          album.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${album.photoCount} Photos',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                onPressed: () => _confirmDeleteAlbum(context, ref),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmDeleteAlbum(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text('Are you sure you want to delete "${album.title}" and all its photos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(galleryRepositoryProvider).deleteAlbum(album.id);
              Navigator.pop(context);
              AppToast.show(context, message: 'Album deleted.', type: ToastType.success);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AlbumDetailsScreen extends ConsumerWidget {
  final GalleryAlbum album;

  const AlbumDetailsScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(albumPhotosProvider(album.id));
    final auth = ref.watch(authProvider);
    final isAdmin = auth.user?.role == 'admin' || auth.user?.role == 'teacher';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${album.title} (${photosAsync.value?.length ?? 0} photos)'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              onPressed: () => _addPhotos(context, ref),
            ),
        ],
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return EmptyState(
              emoji: '🖼️',
              title: 'Empty Album',
              subtitle: 'Add some photos to this album.',
              actionLabel: isAdmin ? 'Add Photos' : null,
              onAction: isAdmin ? () => _addPhotos(context, ref) : null,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (ctx, i) => _PhotoTile(albumId: album.id, photo: photos[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      AppToast.show(context, message: 'Uploading ${result.files.length} photos...', type: ToastType.info);

      final repo = ref.read(galleryRepositoryProvider);
      int successCount = 0;

      for (final file in result.files) {
        try {
          if (kIsWeb && file.bytes == null) continue;
          if (!kIsWeb && file.path == null) continue;

          final url = await repo.uploadPhoto(kIsWeb ? file.bytes : File(file.path!), album.id);
          
          final photo = GalleryPhoto(
            id: '',
            url: url,
            description: file.name,
            createdAt: DateTime.now(),
          );
          
          await repo.addPhotoToAlbum(album.id, photo);
          successCount++;
        } catch (e) {
          debugPrint('Error uploading individual photo: $e');
        }
      }

      if (successCount > 0) {
        AppToast.show(context, message: 'Successfully uploaded $successCount photos!', type: ToastType.success);
      } else {
        AppToast.show(context, message: 'Failed to upload photos.', type: ToastType.error);
      }
    } catch (e) {
      AppToast.show(context, message: 'Error picking photos: $e', type: ToastType.error);
    }
  }
}

class _PhotoTile extends ConsumerWidget {
  final String albumId;
  final GalleryPhoto photo;

  const _PhotoTile({required this.albumId, required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.user?.role == 'admin' || auth.user?.role == 'teacher';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: () => _showFullScreen(context),
              child: Image.network(
                photo.url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 14,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => _deletePhoto(context, ref),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from the album?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(galleryRepositoryProvider).deletePhoto(albumId, photo.id);
      AppToast.show(context, message: 'Photo deleted.', type: ToastType.success);
    }
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(photo.url),
            ),
            if (photo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(photo.description),
              ),
          ],
        ),
      ),
    );
  }
}
