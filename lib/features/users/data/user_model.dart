class User {
  final String id;
  final String name;
  final String email;
  final int? category;
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
    this.category,
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

  static int? _parseCategory(Map<String, dynamic> json) {
    final val = json['studentCategory'] ?? json['StudentCategory'] ?? json['category'] ?? json['Category'];
    if (val == null) return null;
    if (val is int) return val;
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;
      final lower = val.toLowerCase();
      if (lower == 'college') return 0;
      if (lower == 'institute') return 1;
      if (lower == 'equivalence') return 2;
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['userId']).toString(),
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      category: _parseCategory(json),
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
