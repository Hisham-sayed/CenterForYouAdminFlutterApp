import 'dart:io';
import 'data/subject_model.dart';
import '../../core/services/api_service.dart';
import 'data/content_model.dart';
import '../years_terms/data/year_model.dart';

import '../../core/architecture/base_controller.dart';

class SubjectsController extends BaseController {
  List<SubjectCategory> categories = [];

  SubjectsController() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
     await safeCall(() async {
        // Static data matching C# seed
        categories = [
           const SubjectCategory(id: '1', name: 'كلية تجارة'), // Faculty of Commerce
           const SubjectCategory(id: '2', name: 'معهد فني'),   // Technical Institute
           const SubjectCategory(id: '3', name: 'معادلة'),     // Equation
        ];
     });
  }

  // Get years based on category ID (Static Mapping)
  List<AcademicYear> getYearsForCategory(String categoryId) {
    switch (categoryId) {
      case '1': // Faculty of Commerce
        return [
          const AcademicYear(id: '1', name: 'أولى تجارة'),
          const AcademicYear(id: '2', name: 'تانية تجارة'),
          const AcademicYear(id: '3', name: 'تالتة تجارة'),
          const AcademicYear(id: '4', name: 'رابعة تجارة'),
        ];
      case '2': // Technical Institute
        return [
          const AcademicYear(id: '5', name: 'أولى معهد'),
          const AcademicYear(id: '6', name: 'تانية معهد'),
        ];
      case '3': // Equation
        return [
          const AcademicYear(id: '7', name: 'معادلة معهد'),
          const AcademicYear(id: '8', name: 'معادلة دبلوم'),
        ];
      default:
        return [];
    }
  }

  // Get terms based on year ID (Static Mapping)
  List<AcademicTerm> getTermsForYear(String yearId) {
    int yId = int.tryParse(yearId) ?? 0;
    
    // Years 1-6 have Term 1 & 2
    if (yId >= 1 && yId <= 6) {
      return [
        AcademicTerm(id: '${yId * 2 - 1}', name: 'ترم أول'),
        AcademicTerm(id: '${yId * 2}', name: 'ترم تاني'),
      ];
    }
    
    // Years 7-8 are Full Year
    if (yId == 7) return [const AcademicTerm(id: '13', name: 'عام كامل')];
    if (yId == 8) return [const AcademicTerm(id: '14', name: 'عام كامل')];

    return [];
  }

  // --- Subjects ---
  // Store subjects as proper models
  List<Subject> subjects = [];
  List<Exam> exams = [];
  List<Lesson> lessons = [];
  List<Video> videos = [];
  
  Future<void> loadSubjects(String termId) async {
    await safeCall(() async {
      final response = await ApiService().get('/terms/$termId/subjects');
      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final List data = response['data'];
        subjects = data.map((json) => Subject.fromJson(json)).toList();
      } else {
        subjects = [];
      }
    });
  }

  // Add Subject (Requires termId, title, and optional image)
  Future<bool> addSubject(String termId, String title, {File? image}) async {
    return await safeCall(() async {
      final response = await ApiService().postMultipart(
        '/add-subject', 
        { 'TermId': termId, 'Title': title }, // Using PascalCase keys if backend expects them match record properties? 
        // Prompt says: public record AddSubjectRequest(int TermId, string Title...
        // Usually model binding is case-insensitive in ASP.NET, but safer to match or use camelCase. 
        // Previous code used camelCase 'termId'. I will stick to what works or use PasCal if suggested.
        // Quick check: Prompt explicitly showed "public record AddSubjectRequest(int TermId, string Title...)". 
        // Just to be safe, I will send both or stick to standard naming conventions. 
        // Wait, standard ASP.NET Core binds 'termId' to 'TermId' fine.
        // I will use PascalCase to be absolutely sure as per "Ensure duplicate keys match backend contract exactly".
         file: image,
        fileField: 'Image', // PascalCase for IFormFile? Image
      );
      
      if (response != null && response['isSuccess'] == true) {
        await loadSubjects(termId);
      } else {
        throw Exception('Failed to add subject');
      }
    });
  }

  Future<bool> editSubject(String id, String termId, String newTitle, {File? image}) async {
    return await safeCall(() async {
      final response = await ApiService().putMultipart(
        '/update-subject',
        { 'Id': id, 'Title': newTitle }, // Correct keys for UpdateSubjectRequest(int Id, string Title...)
        file: image,
        fileField: 'Image',
      );
      if (response != null && response['isSuccess'] == true) {
        await loadSubjects(termId);
      } else {
         throw Exception('Failed to edit subject');
      }
    });
  }

  Future<bool> deleteSubject(String id, String termId) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/subjects/$id/subject');
      if (response != null && response['isSuccess'] == true) {
        await loadSubjects(termId);
      } else {
         throw Exception('Failed to delete subject');
      }
    });
  }

  // --- Exams ---
  // --- Exams ---
  Future<void> loadExams(String subjectId) async {
    await safeCall(() async {
      final response = await ApiService().get('/subjects/$subjectId/exams');
      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final List data = response['data'];
        exams = data.map((json) => Exam.fromJson(json)).toList();
      } else {
        exams = [];
      }
    });
  }

  Future<bool> addExam(String subjectId, String title, String link) async {
    return await safeCall(() async {
      final response = await ApiService().post(
        '/add-exam',
        body: { 'subjectId': subjectId, 'title': title, 'examLink': link }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadExams(subjectId);
      } else {
        throw Exception('Failed to add exam');
      }
    });
  }

  Future<bool> editExam(String id, String subjectId, String newTitle, String newLink) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/update-exam',
        body: { 
          'id': int.tryParse(id) ?? id, 
          'title': newTitle, 
          'examLink': newLink 
        }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadExams(subjectId);
      } else {
        throw Exception('Failed to edit exam');
      }
    });
  }

  Future<bool> deleteExam(String id, String subjectId) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/exams/$id/exam');
      if (response != null && response['isSuccess'] == true) {
        await loadExams(subjectId);
      } else {
        throw Exception('Failed to delete exam');
      }
    });
  }

  // --- Lessons ---
  Future<void> loadLessons(String subjectId) async {
    await safeCall(() async {
      final response = await ApiService().get('/subjects/$subjectId/lessons');
      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final List data = response['data'];
        lessons = data.map((json) => Lesson.fromJson(json)).toList();
      } else {
        lessons = [];
      }
    });
  }

  Future<bool> addLesson(String subjectId, String title) async {
    return await safeCall(() async {
      final response = await ApiService().post(
        '/add-lesson',
        body: { 'subjectId': subjectId, 'title': title }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadLessons(subjectId);
      } else {
         throw Exception('Failed to add lesson');
      }
    });
  }

  Future<bool> editLesson(String id, String subjectId, String newTitle) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/update-lesson',
        body: { 'id': id, 'title': newTitle }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadLessons(subjectId);
      } else {
         throw Exception('Failed to edit lesson');
      }
    });
  }

  Future<bool> deleteLesson(String id, String subjectId) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/delete-lesson/$id'); // Check endpoint path
      if (response != null && response['isSuccess'] == true) {
        await loadLessons(subjectId);
      } else {
         throw Exception('Failed to delete lesson');
      }
    });
  }

  // --- Videos ---
  Future<void> loadVideosForLesson(String lessonId) async {
    await safeCall(() async {
      final response = await ApiService().get('/lessons/$lessonId/videos');
      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final List data = response['data'];
        videos = data.map((json) => Video.fromJson(json)).toList();
      } else {
        videos = [];
      }
    });
  }

  Future<bool> addVideo(String lessonId, String title, String url) async {
    return await safeCall(() async {
      final response = await ApiService().post(
        '/add-video',
        body: { 'lessonId': lessonId, 'title': title, 'videoLink': url }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadVideosForLesson(lessonId);
      } else {
         throw Exception('Failed to add video');
      }
    });
  }

  Future<bool> editVideo(String id, String lessonId, String title, String url) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/update-video',
        body: { 'id': id, 'title': title, 'videoLink': url }
      );
      if (response != null && response['isSuccess'] == true) {
        await loadVideosForLesson(lessonId);
      } else {
        throw Exception('Failed to edit video');
      }
    });
  }

  Future<bool> deleteVideo(String id, String lessonId) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/delete-video/$id');
      if (response != null && response['isSuccess'] == true) {
        await loadVideosForLesson(lessonId);
      } else {
        throw Exception('Failed to delete video');
      }
    });
  }
}
