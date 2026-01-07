import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String baseUrl = 'https://center-for-you.runasp.net';
  
  // 1. Login
  print('\n[1] Logging in...');
  final loginUri = Uri.parse('$baseUrl/auth/login');
  final loginResp = await http.post(
    loginUri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "email": "admin@centerforyou.com",
      "password": "P@ssword123",
      "deviceId": "admin"
    }),
  );

  if (loginResp.statusCode != 200) {
    print('Login failed: ${loginResp.body}');
    return;
  }
  
  final loginData = jsonDecode(loginResp.body);
  // Handle nested token
  String? token;
  if (loginData.containsKey('token')) {
    token = loginData['token'];
  } else if (loginData['data'] != null && loginData['data']['token'] != null) {
    token = loginData['data']['token'];
  }

  if (token == null) {
      print('Token not found in response: $loginData');
      return;
  }

  print('Login Successful.');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // 2. Get User
  print('\n[2] Checking User (hishamsayed995@gmail.com)...');
  final checkUserUri = Uri.parse('$baseUrl/check-user-exist').replace(queryParameters: {'email': 'hishamsayed995@gmail.com'});
  final checkResp = await http.get(checkUserUri, headers: headers);
  
  if (checkResp.statusCode != 200) {
    print('Check user failed: ${checkResp.body}');
    return;
  }

  final checkData = jsonDecode(checkResp.body);
  final userData = checkData['data'];
  if (userData == null) {
      print("User not found or null data");
      return;
  }
  print('User Data: $userData'); // DEBUG
  final String userId = userData['id'].toString(); // Force to string if int
  final List<dynamic> currentSubjects = userData['enrolledSubjectIds'] ?? [];
  print('User Found: $userId');
  print('Current Subjects: $currentSubjects');

  // 3. Update Subjects
  // Toggle strategy: if empty, add [1]. If has [1], add [2]. If has [1,2], remove 2.
  List<int> newSubjects = [];
  if (currentSubjects.contains(1)) {
     if (currentSubjects.contains(2)) {
         newSubjects = [1]; // Remove 2
     } else {
         newSubjects = [1, 2]; // Add 2
     }
  } else {
     newSubjects = [1]; // Add 1
  }

  print('\n[3] Updating Subjects to: $newSubjects');
  final updateUri = Uri.parse('$baseUrl/update-subjects-to-user');
  final updateBody = {
    "userId": userId,
    "subjectIds": newSubjects
  }; // Using subjectIds (camelCase)
  print('Payload: ${jsonEncode(updateBody)}');

  final updateResp = await http.put(
    updateUri,
    headers: headers,
    body: jsonEncode(updateBody),
  );

  print('Update Response Code: ${updateResp.statusCode}');
  print('Update Response Body: ${updateResp.body}');

  // 4. Verify
  print('\n[4] Verifying Update...');
  final verifyResp = await http.get(checkUserUri, headers: headers);
  final verifyData = jsonDecode(verifyResp.body);
  final verifyUserData = verifyData['data'];
  final List<dynamic> verifiedSubjects = verifyUserData['enrolledSubjectIds'] ?? [];
  
  print('Verified Subjects: $verifiedSubjects');
  bool success = true;
  
  // Strict Set comparison
  var s1 = Set.from(newSubjects);
  var s2 = Set.from(verifiedSubjects.map((e) => e as int));
  
  if (s1.length != s2.length || !s1.containsAll(s2)) {
      success = false;
  }

  if (success) {
      print('SUCCESS: Subjects updated correctly matching target.');
  } else {
      print('FAILURE: Verified subjects do not match target.');
  }
}
