class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl; // Optional
  final String? phoneNumber;
  final String role; // e.g., 'Student'
  final bool hasEnrolledSubjects;
  final List<int> enrolledSubjectIds;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.role = 'Student',
    this.hasEnrolledSubjects = false,
    this.enrolledSubjectIds = const [],
  });
  
  // Helper for initials
  String get initials {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['userId']).toString(),
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'Student',
      avatarUrl: json['avatarUrl'], // nullable
      hasEnrolledSubjects: json['hasEnrolledSubjects'] ?? false,
      enrolledSubjectIds: json['enrolledSubjectIds'] != null 
          ? List<int>.from(json['enrolledSubjectIds']) 
          : const [],
    );
  }
}
