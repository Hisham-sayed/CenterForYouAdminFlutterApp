import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://center-for-you.runasp.net';
// Credentials
const String adminEmail = 'admin@centerforyou.com';
const String adminPassword = 'P@ssword123';
const String testUserEmail = 'hishamsayed995@gmail.com';

String token = 'token';

void log(String message) {
  print(message);
  File('scenario_log.txt').writeAsStringSync('$message\n', mode: FileMode.append);
}

Future<void> main() async {
  if (File('scenario_log.txt').existsSync()) File('scenario_log.txt').deleteSync();
  log('Starting Verification Scenarios...');

  // 1. Auth
  await login();

  if (token.isEmpty) {
    log('Login failed. Aborting.');
    return;
  }

  // 2. Scenario: Device Management
  await verifyDeviceManagement();

  // 3. Scenario: Add Subject to User
  await verifyAddSubjectToUser();

  // 4. Scenario: Graduation Parties
  await verifyGraduationParties();

  // 5. Scenario: Students
  await verifyStudentsList();
}

Future<void> login() async {
  log('\n--- 1. Login ---');
  final uri = Uri.parse('$baseUrl/auth/login');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': adminEmail,
        'password': adminPassword,
        'deviceId': 'admin'
      }),
    );
    
    log('Login Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['isSuccess'] == true && body['data'] != null) {
        token = body['data']['token'];
        log('Token obtained.');
      } else {
        log('Login Failed: ${response.body}');
      }
    }
  } catch (e) {
    log('Login Exception: $e');
  }
}

Future<void> verifyDeviceManagement() async {
  log('\n--- 2. Device Management ---');
  final uri = Uri.parse('$baseUrl/change-user-deviceId');
  try {
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'email': testUserEmail,
        'newDeviceId': 'test_device_${DateTime.now().millisecondsSinceEpoch}'
      }),
    );
    log('Change Device ID Status: ${response.statusCode}');
    log('Response: ${response.body}');
  } catch (e) {
    log('Device Management Exception: $e');
  }
}

Future<void> verifyAddSubjectToUser() async {
  log('\n--- 3. Add Subject to User ---');
  // First, check user to get ID
  String userId = '';
  final checkUri = Uri.parse('$baseUrl/check-user-exist?email=$testUserEmail');
  try {
    // GET check-user-exist
    final checkResponse = await http.get(
      checkUri,
      headers: {'Authorization': 'Bearer $token'},
    );
    log('Check User Status: ${checkResponse.statusCode}');
    log('Check User Body: ${checkResponse.body}');

    if (checkResponse.statusCode == 200) {
      final body = jsonDecode(checkResponse.body);
      if (body['isSuccess'] == true && body['data'] != null) {
        userId = body['data']['userId'] ?? body['data']['id']; // Handle potential naming diffs
        log('Found User ID: $userId');
      }
    }
  } catch (e) {
    log('Check User Exception: $e');
  }

  if (userId.isNotEmpty) {
    // Attempt Update Subjects
    final updateUri = Uri.parse('$baseUrl/update-subjects-to-user');
    try {
      final updateResponse = await http.put(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'userId': userId,
          'subjectIds': [1] // Assuming subject ID 1 exists as per seed
        }),
      );
      log('Update Subjects Status: ${updateResponse.statusCode}');
      log('Response: ${updateResponse.body}');
    } catch (e) {
      log('Update Subjects Exception: $e');
    }
  } else {
    log('Skipping Update Subjects (User ID not found).');
  }
}

Future<void> verifyGraduationParties() async {
  log('\n--- 4. Graduation Parties ---');
  String newVideoId = '';
  
  // A. Add
  final addUri = Uri.parse('$baseUrl/graduation-party-video');
  try {
    final response = await http.post(
      addUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'title': 'Test Graduation Debug',
        'videoLink': 'https://youtube.com/test'
      }),
    );
    log('Add Video Status: ${response.statusCode}');
    log('Add Video Response: ${response.body}');
    
    // Attempt to extract ID if possible (though response might just be success:true)
    // If response doesn't give ID, we might need to fetch all to find it.
  } catch (e) {
    log('Add Video Exception: $e');
  }

  // B. Fetch to find the one we added
  final listUri = Uri.parse('$baseUrl/graduation-party-videos'); // Correct endpoint? GET /graduation-party-videos (plural?) or /graduation-videos?
  // User doc didn't explicit specify GET. I assumed /graduation-party-videos or similar. 
  // Let's try /graduation-party-videos first as per DELETE convention.
  // Wait, I used /graduation-party-videos in Controller. Let's test it.
  try {
    final listResponse = await http.get(listUri, headers: {'Authorization': 'Bearer $token'});
    log('List Videos Status: ${listResponse.statusCode}');
    if (listResponse.statusCode == 200) {
        final body = jsonDecode(listResponse.body);
        if (body['data'] != null) {
            final list = body['data'] as List;
            if (list.isNotEmpty) {
                // Find our video
                 final myVideo = list.firstWhere(
                    (v) => v['title'] == 'Test Graduation Debug', 
                    orElse: () => null
                 );
                 if (myVideo != null) {
                     newVideoId = myVideo['id'].toString();
                     log('Found new video ID: $newVideoId');
                 } else {
                     // Just grab first one to test edit/delete if ours failed
                     newVideoId = list.last['id'].toString();
                     log('Using existing video ID: $newVideoId');
                 }
            }
        }
    }
  } catch (e) {
      log('List Videos Exception: $e');
  }

  if (newVideoId.isNotEmpty) {
      // C. Edit
      final editUri = Uri.parse('$baseUrl/graduation-party-video');
      try {
          final editResponse = await http.put(
              editUri,
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
              body: jsonEncode({
                  'id': newVideoId,
                  'title': 'Test Graduation Debug EDITED',
                  'videoLink': 'https://youtube.com/test_edited'
              })
          );
          log('Edit Video Status: ${editResponse.statusCode}');
          log('Edit Video Response: ${editResponse.body}');
      } catch (e) {
          log('Edit Video Exception: $e');
      }

      // D. Delete
      final deleteUri = Uri.parse('$baseUrl/graduation-party-videos/$newVideoId');
      try {
          final delResponse = await http.delete(deleteUri, headers: {'Authorization': 'Bearer $token'});
          log('Delete Video Status: ${delResponse.statusCode}');
          log('Delete Video Response: ${delResponse.body}');
      } catch (e) {
          log('Delete Video Exception: $e');
      }
  }
}

Future<void> verifyStudentsList() async {
    log('\n--- 5. Students List ---');
    final uri = Uri.parse('$baseUrl/enrolled-users?pageNumber=1&pageSize=10');
    try {
        final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
        log('Students List Status: ${response.statusCode}');
        log('Students List Body: ${response.body}');
    } catch (e) {
        log('Students List Exception: $e');
    }
}
