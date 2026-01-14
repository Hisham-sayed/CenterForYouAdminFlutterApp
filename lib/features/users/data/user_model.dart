class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl; 
  final String? phoneNumber;
  final String role; 
  final bool hasEnrolledSubjects;
  final List<int> enrolledSubjectIds;
  final String? lockoutEnd; // Helper for blocking

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.role = 'Student',
    this.hasEnrolledSubjects = false,
    this.enrolledSubjectIds = const [],
    this.lockoutEnd,
  });
  
  bool get isBlocked {
    if (lockoutEnd == null) return false;
    try {
      final end = DateTime.parse(lockoutEnd!);
      return end.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

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
      avatarUrl: json['avatarUrl'], 
      hasEnrolledSubjects: json['hasEnrolledSubjects'] ?? false,
      enrolledSubjectIds: json['enrolledSubjectIds'] != null 
          ? List<int>.from(json['enrolledSubjectIds']) 
          : const [],
      lockoutEnd: json['lockoutEnd'],
    );
  }
}
