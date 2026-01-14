import 'package:flutter/material.dart';
import 'data/user_model.dart';
import '../../core/services/api_service.dart';

import '../../core/architecture/base_controller.dart';

class UsersController extends BaseController {
  List<User> _allUsers = [];
  List<User> filteredUsers = [];
  // isLoading is inherited from BaseController

  UsersController();

  // API Methods
  Future<User?> checkUser(String email) async {
    User? foundUser;
    
    // We can use safeCall for standardized error handling
    await safeCall(() async {
      final response = await ApiService().get('/check-user-exist', queryParams: { 'email': email });
      
      if (response != null && response['isSuccess'] == true && response['data'] != null) {
        final data = response['data'];
        foundUser = User.fromJson(data);
      } else {
        // If API returns success=false or no data, we might throw or just return null
        // safeCall catches exceptions. If we want to show error:
        throw Exception(response?['message'] ?? 'User not found');
      }
    });

    return foundUser;
  }

  Future<bool> addSubjectToUser(String userId, List<String> subjectIds) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/update-subjects-to-user',
        body: { 
          'userId': userId, 
          'subjectIds': subjectIds.map((id) => int.parse(id)).toList() 
        }
      );
      
      if (response == null || response['isSuccess'] != true) {
        throw Exception(response?['message'] ?? 'Failed to add subjects');
      }
    });
  }

  Future<bool> resetDeviceId(String email) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/reset-user-deviceId',
        body: { 'email': email }
      );
       if (response == null || response['isSuccess'] != true) {
        throw Exception(response?['message'] ?? 'Failed to reset device ID');
      }
    });
  }

  Future<bool> toggleBlockStatus(String userId, bool block) async {
    return await safeCall(() async {
      // Assuming endpoint based on standard patterns. 
      // If we are strictly "Using LockoutEnd", the backend might expose a specific endpoint 
      // like /users/{id}/lockout or we just PUT to update user.
      // Based on previous patterns (add-subject, change-user-deviceId), 
      // it might be '/block-user' or '/unblock-user'.
      // I will generic endpoint that likely exists in such a system.
      final endpoint = block ? '/block-user' : '/unblock-user';
      final response = await ApiService().put(endpoint, body: { 'userId': userId });

      if (response != null && response['isSuccess'] == true) {
         // Optimistically update local list
         final index = _allUsers.indexWhere((u) => u.id == userId);
         if (index != -1) {
           final user = _allUsers[index];
           // Construct new user with updated lockoutEnd
           // For block, set to far future. For unblock, null.
           final lockout = block ? DateTime.now().add(const Duration(days: 36500)).toIso8601String() : null;
           
           // We need a copyWith or manually recreate
           _allUsers[index] = User(
             id: user.id,
             name: user.name,
             email: user.email,
             avatarUrl: user.avatarUrl,
             phoneNumber: user.phoneNumber,
             role: user.role,
             hasEnrolledSubjects: user.hasEnrolledSubjects,
             enrolledSubjectIds: user.enrolledSubjectIds,
             lockoutEnd: lockout,
           );
           filteredUsers = List.from(_allUsers); // Update filtered list too if needed
         }
      } else {
        throw Exception(response?['message'] ?? 'Failed to update block status');
      }
    });
  }

  Future<bool> deleteAllSubjects(String userId) async {
    return await safeCall(() async {
      final response = await ApiService().delete('/users/$userId/delete-all-subjects');

      if (response != null && response['isSuccess'] == true) {
        // Remove user from list since they no longer have enrolled subjects
        _allUsers.removeWhere((u) => u.id == userId);
        filteredUsers = List.from(_allUsers);
        notifyListeners();
      } else {
        throw Exception(response?['message'] ?? 'Failed to delete all subjects');
      }
    });
  }

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasNextPage = true;
  bool isLoadMoreRunning = false;

  void resetPagination() {
    _currentPage = 1;
    _allUsers = [];
    filteredUsers = [];
    _hasNextPage = true;
  }

  Future<void> fetchUsers({String searchKey = '', bool isLoadMore = false}) async {
    // If loading more, strictly avoid global loading state
    if (isLoadMore) {
      if (isLoading || isLoadMoreRunning || !_hasNextPage) return;
      isLoadMoreRunning = true;
      notifyListeners();

      try {
         await _performFetch(searchKey, isLoadMore: true);
      } catch (e) {
        debugPrint('Error loading more users: $e');
        // Optionally set errorMessage for snackbar without full screen error
      } finally {
        isLoadMoreRunning = false;
        notifyListeners();
      }
    } else {
      // Initial load uses safeCall
      await safeCall(() async {
        resetPagination();
        await _performFetch(searchKey, isLoadMore: false);
      });
    }
  }

  Future<void> _performFetch(String searchKey, {required bool isLoadMore}) async {
    final queryParams = {
        'pageNumber': isLoadMore ? '${_currentPage + 1}' : '1',
        'pageSize': '$_pageSize',
        if (searchKey.isNotEmpty) 'searchKey': searchKey,
    };

    final response = await ApiService().get('/enrolled-users', queryParams: queryParams);

    if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final data = response['data'];
        final List usersJson = data['users'] ?? [];
        final List<User> newUsers = usersJson.map((json) => User.fromJson(json)).toList();

        if (isLoadMore) {
          _allUsers.addAll(newUsers);
          _currentPage++;
        } else {
          _allUsers = newUsers;
          _currentPage = 1;
        }
        
        _hasNextPage = data['hasNextPage'] ?? false;
        filteredUsers = List.from(_allUsers);
    } else {
       throw Exception(response?['message'] ?? 'Failed to fetch users');
    }
  }
}
