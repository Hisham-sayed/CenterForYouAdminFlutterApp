import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/screens/secure_video_player_screen.dart';
import '../data/content_model.dart';
import '../subjects_controller.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_form_field.dart';
import '../../../../shared/widgets/app_dialog.dart';

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
      builder: (context) => AppDialog(
        title: existingVideo == null ? 'Add Video' : 'Edit Video',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
              controller: _controller,
              fieldName: 'title',
              textEditingController: titleController,
              hintText: 'Video Title',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _controller,
              fieldName: 'url',
              textEditingController: urlController,
              hintText: 'Video URL (YouTube/Vimeo)',
            ),
          ],
        ),
        onConfirm: () async {
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
             if (_controller.hasError && !_controller.hasValidationErrors) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.errorMessage ?? 'An error occurred')),
               );
             }
          }
        },
      ),
    );
  }

  void _deleteVideo(Video video) {
    final lessonId = lesson?.id ?? '0';
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Delete Video',
        content: const Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
        confirmText: 'Delete',
        onConfirm: () async {
          final success = await _controller.deleteVideo(video.id, lessonId);
          if (!context.mounted) return;
          if (success) {
            Navigator.pop(context);
          } else {
             if (_controller.hasError) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.validationSummary)),
               );
             }
          }
        },
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
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (video.url.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    video.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                            onPressed: () => _showAddEditDialog(existingVideo: video),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => _deleteVideo(video),
                          ),
                        ],
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
