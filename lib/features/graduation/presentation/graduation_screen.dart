import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Added dependency
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/screens/secure_video_player_screen.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_dialog.dart';
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
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: isEditing ? 'Edit Graduation Party' : 'Add Graduation Party',
        controller: _controller,
        loadingText: 'Saving...',
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
        onCancel: () {
           _controller.clearErrors(); 
           Navigator.pop(context);
        },
        onConfirm: () async {
          if (titleController.text.isNotEmpty) {
             bool success;
             if (isEditing) {
               success = await _controller.editVideo(video.id, titleController.text, urlController.text);
             } else {
               success = await _controller.addVideo(titleController.text, urlController.text);
             }
             
            if (!context.mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Video updated successfully' : 'Video added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else {
               // Only show SnackBar for generic errors (non-validation)
               // Validation errors are now shown inline on the fields.
               if (_controller.hasError && !_controller.hasValidationErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_controller.errorMessage ?? 'An error occurred')),
                  );
               }
            }
          }
        },
      ),
    );
  }

  void _deleteVideo(GraduationVideo video) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: 'Delete Party',
        content: const Text('Are you sure you want to delete this video?', style: TextStyle(color: AppColors.textSecondary)),
        controller: _controller,
        confirmText: 'Delete',
        loadingText: 'Deleting...',
        onConfirm: () async {
          final success = await _controller.deleteVideo(video.id);
          if (!context.mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
             if (_controller.hasError && !_controller.hasValidationErrors) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.errorMessage ?? 'Error deleting video')),
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _controller.videos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final video = _controller.videos[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column( // Changed from Stack to Column to allow content to grow naturally below image/placeholder
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Video Preview / Placeholder
                     Container(
                       height: 200, // Fixed height for media preview is standard
                       width: double.infinity,
                       decoration: const BoxDecoration(
                         image: DecorationImage(
                           image: AssetImage('assets/images/graduation_party_bg.png'),
                           fit: BoxFit.cover,
                         ),
                       ),
                       child: Container(
                         // Subtle dark overlay for better text contrast if needed
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter,
                             colors: [
                               Colors.transparent,
                               Colors.black.withValues(alpha: 0.3),
                             ],
                           ),
                         ),
                       ),
                     ),
                     
                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary, // Adjusted color since it's not on dark overlay anymore
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
