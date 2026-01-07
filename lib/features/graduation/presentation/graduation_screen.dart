import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Added dependency
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/screens/secure_video_player_screen.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../graduation_controller.dart';
import '../data/graduation_video_model.dart'; 

class GraduationPartiesScreen extends StatefulWidget {
  const GraduationPartiesScreen({super.key});

  @override
  State<GraduationPartiesScreen> createState() => _GraduationPartiesScreenState();
}

class _GraduationPartiesScreenState extends State<GraduationPartiesScreen> {
  final GraduationController _controller = GraduationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddEditDialog({GraduationVideo? video}) {
    final TextEditingController titleController = TextEditingController(text: video?.title ?? '');
    final TextEditingController urlController = TextEditingController(text: video?.videoLink ?? '');
    final bool isEditing = video != null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isEditing ? 'Edit Graduation Party' : 'Add Graduation Party', style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
              controller: _controller, // BaseController for validation
              fieldName: 'title', // Server key
              textEditingController: titleController,
              hintText: 'Title (e.g. Class of 2025)',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _controller,
              fieldName: 'videoLink',
              textEditingController: urlController,
              hintText: 'Video URL',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               _controller.clearErrors(); // Clear previous errors on close
               Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                 bool success;
                 if (isEditing) {
                   success = await _controller.editVideo(video.id, titleController.text, urlController.text);
                 } else {
                   success = await _controller.addVideo(titleController.text, urlController.text);
                 }
                 
                if (!context.mounted) return;
                if (success) {
                  Navigator.pop(context);
                } else {
                  // If not validation error (which shows inline), show generic
                  if (_controller.validationErrors == null && _controller.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_controller.errorMessage!)),
                    );
                  } else if (_controller.validationErrors == null && _controller.errorMessage == null) {
                     // Fallback
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to ${isEditing ? 'edit' : 'add'} video.')),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(GraduationVideo video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Party', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to delete this video?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final success = await _controller.deleteVideo(video.id);
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
      title: 'Graduation Parties',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black), // Fixed Icon: add instead of add_a_photo
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }
          if (_controller.videos.isEmpty) {
             return const Center(child: Text('No videos found', style: TextStyle(color: AppColors.textSecondary)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Full width cards look better for video placeholders
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: _controller.videos.length,
            itemBuilder: (context, index) {
              final video = _controller.videos[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                     // Placeholder Image
                    Container(
                      color: AppColors.surfaceHighlight,
                      child: Center(
                        child: Icon(
                          Icons.movie_creation_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Overlay Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _openSecurePlayer(video.videoLink, video.title);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Watch'),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _showAddEditDialog(video: video),
                                icon: const Icon(Icons.edit, color: AppColors.textPrimary),
                              ),
                              IconButton(
                                onPressed: () => _deleteVideo(video),
                                icon: const Icon(Icons.delete, color: AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
