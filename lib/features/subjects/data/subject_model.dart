enum Section {
  taxation(1),
  institutions(2);

  final int value;
  const Section(this.value);

  static Section fromValue(int val) {
    return Section.values.firstWhere((e) => e.value == val, orElse: () => Section.taxation);
  }
}

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
  final Section section;

  const Subject({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.section = Section.taxation,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    int sectionIndex = json['section'] ?? 1;
    Section parsedSection = Section.fromValue(sectionIndex);

    return Subject(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      section: parsedSection,
    );
  }
}
