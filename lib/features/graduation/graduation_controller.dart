import 'package:flutter/material.dart';

import 'data/graduation_video_model.dart';
import '../../core/services/api_service.dart';

import '../../core/architecture/base_controller.dart';

class GraduationController extends BaseController {
  List<GraduationVideo> videos = [];

  GraduationController() {
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    await safeCall(() async {
      final response = await ApiService().get('/graduation-party-videos'); 
      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final List data = response['data'];
        videos = data.map((json) => GraduationVideo.fromJson(json)).toList();
      } else {
        videos = [];
      }
    });
  }

  Future<bool> addVideo(String title, String url) async {
    return await safeCall(() async {
      final response = await ApiService().post(
        '/graduation-party-video',
        body: { 'title': title, 'videoLink': url }
      );
      if (response == null || response['isSuccess'] != true) {
         throw Exception(response?['message'] ?? 'Failed to add video');
      }
      // Refresh list
      await fetchVideos();  
    });
  }

  Future<bool> editVideo(String id, String title, String url) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/graduation-party-video',
        body: { 'id': id, 'title': title, 'videoLink': url }
      );
      if (response == null || response['isSuccess'] != true) {
         throw Exception(response?['message'] ?? 'Failed to edit video');
      }
      await fetchVideos();
    });
  }

  Future<bool> deleteVideo(String id) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/graduation-party-videos/$id');
      if (response == null || response['isSuccess'] != true) {
         throw Exception(response?['message'] ?? 'Failed to delete video');
      }
      await fetchVideos();
    });
  }
}
