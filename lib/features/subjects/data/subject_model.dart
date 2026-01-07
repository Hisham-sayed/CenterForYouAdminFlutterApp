class SubjectCategory {
  final String id;
  final String name;
  final String iconPath; // Or IconData for now

  const SubjectCategory({
    required this.id,
    required this.name,
    this.iconPath = '',
  });

}

class Subject {
  final String id;
  final String title;
  final String imageUrl;

  const Subject({
    required this.id,
    required this.title,
    this.imageUrl = '',
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
