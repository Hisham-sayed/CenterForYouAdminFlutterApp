import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/screens/secure_video_player_screen.dart';
import '../data/content_model.dart';
import '../subjects_controller.dart';
import '../../../../shared/widgets/app_text_field.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final SubjectsController _controller = SubjectsController();
  bool _initialized = false;

  // Arguments
  Lesson? lesson;
  List<String> breadcrumbs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['data'] is Lesson) {
          lesson = args['data'] as Lesson?;
        }
        breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
      } else if (args is Lesson) {
        lesson = args;
      }
      
      _controller.loadVideosForLesson(lesson?.id ?? '0');
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddEditDialog({Video? existingVideo}) {
    final TextEditingController titleController = TextEditingController(text: existingVideo?.title);
    final TextEditingController urlController = TextEditingController(text: existingVideo?.url);
    final lessonId = lesson?.id ?? '0';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(existingVideo == null ? 'Add Video' : 'Edit Video', 
          style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleController,
              hintText: 'Video Title',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: urlController,
              hintText: 'Video URL (YouTube/Vimeo)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = false;
              if (existingVideo == null) {
                success = await _controller.addVideo(lessonId, titleController.text, urlController.text);
              } else {
                success = await _controller.editVideo(existingVideo.id, lessonId, titleController.text, urlController.text);
              }
              
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save video.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(Video video) {
    final lessonId = lesson?.id ?? '0';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Video', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final success = await _controller.deleteVideo(video.id, lessonId);
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete video.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // Helper to open secure player
  void _openSecurePlayer(String urlString, String title) {
    if (urlString.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecureVideoPlayerScreen(
          videoUrl: urlString,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Videos',
      breadcrumbs: [...breadcrumbs, 'Videos'],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.videos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final video = _controller.videos[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                  ),
                  title: Text(
                    video.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    video.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                        onPressed: () => _showAddEditDialog(existingVideo: video),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _deleteVideo(video),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _openSecurePlayer(video.url, video.title);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceHighlight,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Watch'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
