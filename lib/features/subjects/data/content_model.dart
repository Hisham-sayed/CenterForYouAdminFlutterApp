class Exam {
  final String id;
  final String title;
  final String? link;
  final DateTime? date;

  const Exam({required this.id, required this.title, this.link, this.date});

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'].toString(),
      title: json['title'] ?? json['Title'] ?? '',
      // Check all possible casing/naming conventions
      link: json['examLink'] ?? json['ExamLink'] ?? json['link'] ?? json['Link'] ?? json['url'] ?? json['Url'] ?? '', 
      date: json['createdOn'] != null ? DateTime.tryParse(json['createdOn']) : null,
    );
  }
}

class Lesson {
  final String id;
  final String title;

  const Lesson({required this.id, required this.title});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'].toString(),
      title: json['title'] ?? '',
    );
  }
}

class Video {
  final String id;
  final String title;
  final String url;

  const Video({required this.id, required this.title, required this.url});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      url: json['videoLink'] ?? json['url'] ?? '', // Map videoLink
    );
  }
}
