class GraduationVideo {
  final String id;
  final String title;
  final String videoLink;

  const GraduationVideo({
    required this.id,
    required this.title,
    required this.videoLink,
  });

  factory GraduationVideo.fromJson(Map<String, dynamic> json) {
    return GraduationVideo(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      videoLink: json['videoLink'] ?? '',
    );
  }
}
